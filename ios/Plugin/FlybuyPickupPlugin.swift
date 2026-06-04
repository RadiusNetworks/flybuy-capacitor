import Capacitor
import FlyBuy
import FlyBuyPickup

@objc(FlybuyPickupPlugin)
public class FlybuyPickupPlugin: CAPPlugin {

    // MARK: - Instance Helper

    private func getInstance(_ call: CAPPluginCall) -> FlyBuy.Instance {
        let appAuthId = call.getString("appAuthId")
        return try! FlyBuy.Core.getInstance(forAppAuthId: appAuthId)
    }

    // MARK: - Order Observers

    private var orderObservers: [NSObjectProtocol] = []

    public override func load() {
        let updatedObserver = NotificationCenter.default.addObserver(
            forName: .ordersUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let orders = (try? FlyBuy.Core.getInstance(forAppAuthId: nil))?.orders.all ?? []
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
            if let order = notification.object as? Order {
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
        getInstance(call).orders.fetch { orders, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve(["orders": (orders ?? []).map { self.serializeOrder($0) }])
        }
    }

    @objc func getOrders(_ call: CAPPluginCall) {
        let filter = call.getString("filter") ?? "all"
        let instance = getInstance(call)
        let orders: [Order]
        switch filter {
        case "open":   orders = instance.orders.open
        case "closed": orders = instance.orders.closed
        default:       orders = instance.orders.all
        }
        call.resolve(["orders": orders.map { serializeOrder($0) }])
    }

    @objc func fetchOrderByRedemptionCode(_ call: CAPPluginCall) {
        guard let code = call.getString("redemptionCode") else {
            return call.reject("redemptionCode is required", "INVALID_ARGUMENT")
        }
        getInstance(call).orders.fetch(withRedemptionCode: code) { order, error in
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
        getInstance(call).orders.create(siteID: siteID, orderOptions: orderOptions) { order, error in
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
        getInstance(call).orders.create(
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
        getInstance(call).orders.claim(
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
        getInstance(call).orders.updateOrderState(orderID: orderID, state: state) { order, error in
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
            getInstance(call).orders.updateCustomerState(
                orderID: orderID, customerState: customerState, spotIdentifier: spotIdentifier
            ) { order, error in
                if let error = error { return self.rejectWithError(call, error) }
                guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
                call.resolve(["order": self.serializeOrder(order)])
            }
        } else {
            getInstance(call).orders.updateCustomerState(
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
        getInstance(call).orders.updatePickupMethod(
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
        getInstance(call).orders.rateOrder(
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

    private func serializeOrder(_ order: Order) -> [String: Any] {
        var dict: [String: Any] = [
            "id": order.id,
            "state": order.state,
            "customerState": order.customerState,
            "isOpen": order.isOpen(),
            "siteID": order.siteID,
        ]
        if let partnerIdentifier = order.partnerIdentifier { dict["partnerIdentifier"] = partnerIdentifier }
        if let redeemedAt = order.redeemedAt { dict["redeemedAt"] = ISO8601DateFormatter().string(from: redeemedAt) }
        if let rating = order.customerRating { dict["customerRatingValue"] = rating }
        if let spotEnabled = order.spotIdentifierEntryEnabled { dict["spotIdentifierEntryEnabled"] = spotEnabled }
        if let pickupType = order.pickupType { dict["pickupType"] = pickupType }
        if let customerName = order.customerName { dict["customerName"] = customerName }
        if let customerCarType = order.customerCarType { dict["customerCarType"] = customerCarType }
        if let customerCarColor = order.customerCarColor { dict["customerCarColor"] = customerCarColor }
        if let customerLicensePlate = order.customerLicensePlate { dict["customerCarPlate"] = customerLicensePlate }
        if let eta = order.etaAt { dict["etaAtStop"] = ISO8601DateFormatter().string(from: eta) }
        if let window = order.pickupWindow {
            var windowDict: [String: Any] = ["start": ISO8601DateFormatter().string(from: window.start)]
            windowDict["end"] = ISO8601DateFormatter().string(from: window.end)
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
        if let pickupType = dict["pickupType"] as? String { builder.setPickupType(pickupType) }
        if let state = dict["state"] as? String { builder.setState(state) }
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