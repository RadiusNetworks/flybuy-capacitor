import Capacitor
import FlyBuy
import FlyBuyPickup

@objc(FlybuyPickupPlugin)
public class FlybuyPickupPlugin: CAPPlugin {

    // MARK: - Order Observers

    private var orderObservers: [NSObjectProtocol] = []

    public override func load() {
        let updatedObserver = NotificationCenter.default.addObserver(
            forName: .ordersUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let orders = FlyBuy.Core.getInstance().orders.all
            self.notifyListeners("ordersUpdated", data: [
                "orders": orders.map { self.serializeOrder($0) }
            ])
        }

        let singleObserver = NotificationCenter.default.addObserver(
            forName: .orderUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let order = notification.object as? FlyBuyOrder {
                self.notifyListeners("orderUpdated", data: [
                    "order": self.serializeOrder(order)
                ])
            }
        }

        let errorObserver = NotificationCenter.default.addObserver(
            forName: .ordersError,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let error = notification.object as? Error {
                self.notifyListeners("ordersError", data: [
                    "error": error.localizedDescription
                ])
            }
        }

        orderObservers = [updatedObserver, singleObserver, errorObserver]
    }

    deinit {
        orderObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Orders

    @objc func fetchOrders(_ call: CAPPluginCall) {
        FlyBuy.Core.getInstance().orders.fetch { orders, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve(["orders": (orders ?? []).map { self.serializeOrder($0) }])
        }
    }

    @objc func getOrders(_ call: CAPPluginCall) {
        let filter = call.getString("filter") ?? "all"
        let orders: [FlyBuyOrder]
        switch filter {
        case "open":   orders = FlyBuy.Core.getInstance().orders.open
        case "closed": orders = FlyBuy.Core.getInstance().orders.closed
        default:       orders = FlyBuy.Core.getInstance().orders.all
        }
        call.resolve(["orders": orders.map { serializeOrder($0) }])
    }

    @objc func fetchOrderByRedemptionCode(_ call: CAPPluginCall) {
        guard let code = call.getString("redemptionCode") else {
            return call.reject("redemptionCode is required", "INVALID_ARGUMENT")
        }
        FlyBuy.Core.getInstance().orders.fetch(withRedemptionCode: code) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order found", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    @objc func createOrderBySiteID(_ call: CAPPluginCall) {
        guard let siteID = call.getInt("siteID"),
              let orderOptionsDict = call.getObject("orderOptions"),
              let orderOptions = buildOrderOptions(from: orderOptionsDict) else {
            return call.reject("siteID and orderOptions.customerName are required", "INVALID_ARGUMENT")
        }
        FlyBuy.Core.getInstance().orders.create(siteID: siteID, orderOptions: orderOptions) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    @objc func createOrderBySitePartnerIdentifier(_ call: CAPPluginCall) {
        guard let sitePartnerIdentifier = call.getString("sitePartnerIdentifier"),
              let orderOptionsDict = call.getObject("orderOptions"),
              let orderOptions = buildOrderOptions(from: orderOptionsDict) else {
            return call.reject("sitePartnerIdentifier and orderOptions.customerName are required", "INVALID_ARGUMENT")
        }
        FlyBuy.Core.getInstance().orders.create(
            sitePartnerIdentifier: sitePartnerIdentifier,
            orderOptions: orderOptions
        ) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    @objc func claimOrder(_ call: CAPPluginCall) {
        guard let code = call.getString("redemptionCode"),
              let orderOptionsDict = call.getObject("orderOptions"),
              let orderOptions = buildOrderOptions(from: orderOptionsDict) else {
            return call.reject("redemptionCode and orderOptions.customerName are required", "INVALID_ARGUMENT")
        }
        FlyBuy.Core.getInstance().orders.claim(
            withRedemptionCode: code,
            orderOptions: orderOptions
        ) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    @objc func updateOrderState(_ call: CAPPluginCall) {
        guard let orderID = call.getInt("orderID"),
              let state = call.getString("state") else {
            return call.reject("orderID and state are required", "INVALID_ARGUMENT")
        }
        FlyBuy.Core.getInstance().orders.updateOrderState(orderID: orderID, state: state) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    @objc func updateOrderCustomerState(_ call: CAPPluginCall) {
        guard let orderID = call.getInt("orderID"),
              let customerState = call.getString("customerState") else {
            return call.reject("orderID and customerState are required", "INVALID_ARGUMENT")
        }
        let spotIdentifier = call.getString("spotIdentifier")
        if let spotIdentifier = spotIdentifier {
            FlyBuy.Core.getInstance().orders.updateCustomerState(
                orderID: orderID, customerState: customerState, spotIdentifier: spotIdentifier
            ) { order, error in
                if let error = error { return self.rejectWithError(call, error) }
                guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
                call.resolve(["order": self.serializeOrder(order)])
            }
        } else {
            FlyBuy.Core.getInstance().orders.updateCustomerState(
                orderID: orderID, customerState: customerState
            ) { order, error in
                if let error = error { return self.rejectWithError(call, error) }
                guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
                call.resolve(["order": self.serializeOrder(order)])
            }
        }
    }

    @objc func updatePickupMethod(_ call: CAPPluginCall) {
        guard let orderID = call.getInt("orderID"),
              let pickupType = call.getString("pickupType") else {
            return call.reject("orderID and pickupType are required", "INVALID_ARGUMENT")
        }
        let builder = PickupMethodOptions.Builder(pickupType: pickupType)
        if let carType = call.getString("customerCarType") { builder.setCustomerCarType(carType) }
        if let carColor = call.getString("customerCarColor") { builder.setCustomerCarColor(carColor) }
        if let licensePlate = call.getString("customerLicensePlate") { builder.setCustomerLicensePlate(licensePlate) }
        if let handoffLocation = call.getString("handoffVehicleLocation") { builder.setHandoffVehicleLocation(handoffLocation) }
        FlyBuy.Core.getInstance().orders.updatePickupMethod(
            orderID: orderID, pickupMethodOptions: builder.build()
        ) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    @objc func rateOrder(_ call: CAPPluginCall) {
        guard let orderID = call.getInt("orderID"),
              let rating = call.getInt("rating") else {
            return call.reject("orderID and rating are required", "INVALID_ARGUMENT")
        }
        let comments = call.getString("comments")
        let categories = call.getArray("categories", String.self) ?? []
        FlyBuy.Core.getInstance().orders.rateOrder(
            orderID: orderID, rating: rating, comments: comments, categories: categories
        ) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    // MARK: - Error Handling

    private func rejectWithError(_ call: CAPPluginCall, _ error: Error) {
        switch error {
        case let ordersError as OrdersManagerError:
            call.reject(ordersError.errorDescription ?? error.localizedDescription, "ORDERS_ERROR")
        case let apiError as FlyBuyAPIError:
            call.reject(error.localizedDescription, "API_ERROR", error, ["statusCode": apiError.statusCodeInt])
        case let commonError as FlyBuyError:
            call.reject(commonError.errorDescription ?? error.localizedDescription, "FLYBUY_ERROR")
        default:
            call.reject(error.localizedDescription, "UNKNOWN_ERROR")
        }
    }

    // MARK: - Serializers

    private func serializeOrder(_ order: FlyBuyOrder) -> [String: Any] {
        var dict: [String: Any] = [
            "id": order.id,
            "state": order.state.rawValue,
            "customerState": order.customerState.rawValue,
            "isOpen": order.isOpen(),
            "siteID": order.siteID,
        ]
        if let partnerIdentifier = order.partnerIdentifier { dict["partnerIdentifier"] = partnerIdentifier }
        if let partnerIdentifierForCrew = order.partnerIdentifierForCrew { dict["partnerIdentifierForCrew"] = partnerIdentifierForCrew }
        if let partnerIdentifierForCustomer = order.partnerIdentifierForCustomer { dict["partnerIdentifierForCustomer"] = partnerIdentifierForCustomer }
        if let redeemedAt = order.redeemedAt { dict["redeemedAt"] = ISO8601DateFormatter().string(from: redeemedAt) }
        if let rating = order.customerRatingValue { dict["customerRatingValue"] = rating }
        if let spotEnabled = order.spotIdentifierEntryEnabled { dict["spotIdentifierEntryEnabled"] = spotEnabled }
        if let spotInputType = order.spotIdentifierInputType { dict["spotIdentifierInputType"] = spotInputType }
        if let pickupType = order.pickupType { dict["pickupType"] = pickupType }
        if let customerName = order.customerName { dict["customerName"] = customerName }
        if let customerCarType = order.customerCarType { dict["customerCarType"] = customerCarType }
        if let customerCarColor = order.customerCarColor { dict["customerCarColor"] = customerCarColor }
        if let customerCarPlate = order.customerCarPlate { dict["customerCarPlate"] = customerCarPlate }
        if let eta = order.etaAtStop { dict["etaAtStop"] = ISO8601DateFormatter().string(from: eta) }
        if let window = order.pickupWindow {
            var windowDict: [String: Any] = ["start": ISO8601DateFormatter().string(from: window.start)]
            if let end = window.end { windowDict["end"] = ISO8601DateFormatter().string(from: end) }
            dict["pickupWindow"] = windowDict
        }
        return dict
    }

    // MARK: - Builders

    private func buildOrderOptions(from dict: [String: Any]) -> OrderOptions? {
        guard let customerName = dict["customerName"] as? String else { return nil }
        let builder = OrderOptions.Builder(customerName: customerName)
        if let phone = dict["customerPhone"] as? String { builder.setCustomerPhone(phone) }
        if let carColor = dict["customerCarColor"] as? String { builder.setCustomerCarColor(carColor) }
        if let carType = dict["customerCarType"] as? String { builder.setCustomerCarType(carType) }
        if let carPlate = dict["customerCarPlate"] as? String { builder.setCustomerCarPlate(carPlate) }
        if let partnerIdentifier = dict["partnerIdentifier"] as? String { builder.setPartnerIdentifier(partnerIdentifier) }
        if let partnerIdentifierForCrew = dict["partnerIdentifierForCrew"] as? String { builder.setPartnerIdentifierForCrew(partnerIdentifierForCrew) }
        if let partnerIdentifierForCustomer = dict["partnerIdentifierForCustomer"] as? String { builder.setPartnerIdentifierForCustomer(partnerIdentifierForCustomer) }
        if let pickupType = dict["pickupType"] as? String { builder.setPickupType(pickupType) }
        if let state = dict["state"] as? String { builder.setState(state) }
        if let transportMode = dict["transportMode"] as? String { builder.setTransportMode(transportMode) }
        if let handoffLocation = dict["handoffVehicleLocation"] as? String { builder.setHandoffVehicleLocation(handoffLocation) }
        if let loyaltyId = dict["loyaltyIdentifier"] as? String,
           let loyaltyProvider = dict["loyaltyProvider"] as? String {
            builder.setLoyaltyInfo(identifier: loyaltyId, provider: loyaltyProvider)
        }
        if let disableOrderFire = dict["disableOrderFire"] as? Bool { builder.setDisableOrderFire(disableOrderFire) }
        if let disablePromiseTime = dict["disablePromiseTimeScheduling"] as? Bool { builder.setDisablePromiseTimeScheduling(disablePromiseTime) }
        if let fireInterval = dict["orderFireMakeIntervalSeconds"] as? Int { builder.setOrderFireMakeIntervalSeconds(fireInterval) }
        if let windowDict = dict["pickupWindow"] as? [String: Any],
           let startStr = windowDict["start"] as? String,
           let startDate = ISO8601DateFormatter().date(from: startStr) {
            if let endStr = windowDict["end"] as? String,
               let endDate = ISO8601DateFormatter().date(from: endStr) {
                builder.setPickupWindow(PickupWindow(start: startDate, end: endDate))
            } else {
                builder.setPickupWindow(PickupWindow(startDate))
            }
        }
        return builder.build()
    }
}
