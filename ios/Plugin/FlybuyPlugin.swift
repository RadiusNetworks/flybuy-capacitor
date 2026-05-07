import Capacitor
import CoreLocation
import FlyBuy
import FlyBuyPickup
import FlyBuyNotify

@objc(FlybuyPlugin)
public class FlybuyPlugin: CAPPlugin {

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
        orderObservers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }

    // MARK: - Orders

    @objc func fetchOrders(_ call: CAPPluginCall) {
        FlyBuy.Core.getInstance().orders.fetch { orders, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve([
                "orders": (orders ?? []).map { self.serializeOrder($0) }
            ])
        }
    }

    @objc func getOrders(_ call: CAPPluginCall) {
        let filter = call.getString("filter") ?? "all"
        let orders: [FlyBuyOrder]

        switch filter {
        case "open":
            orders = FlyBuy.Core.getInstance().orders.open
        case "closed":
            orders = FlyBuy.Core.getInstance().orders.closed
        default:
            orders = FlyBuy.Core.getInstance().orders.all
        }

        call.resolve(["orders": orders.map { serializeOrder($0) }])
    }

    @objc func fetchOrderByRedemptionCode(_ call: CAPPluginCall) {
        guard let code = call.getString("redemptionCode") else {
            return call.reject("redemptionCode is required", "INVALID_ARGUMENT")
        }

        FlyBuy.Core.getInstance().orders.fetch(withRedemptionCode: code) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else {
                return call.reject("No order found", "NOT_FOUND")
            }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    @objc func createOrderBySiteID(_ call: CAPPluginCall) {
        guard let siteID = call.getInt("siteID"),
              let orderOptionsDict = call.getObject("orderOptions") else {
            return call.reject("siteID and orderOptions are required", "INVALID_ARGUMENT")
        }
        guard let orderOptions = buildOrderOptions(from: orderOptionsDict) else {
            return call.reject("customerName is required in orderOptions", "INVALID_ARGUMENT")
        }

        FlyBuy.Core.getInstance().orders.create(siteID: siteID, orderOptions: orderOptions) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    @objc func createOrderBySitePartnerIdentifier(_ call: CAPPluginCall) {
        guard let sitePartnerIdentifier = call.getString("sitePartnerIdentifier"),
              let orderOptionsDict = call.getObject("orderOptions") else {
            return call.reject("sitePartnerIdentifier and orderOptions are required", "INVALID_ARGUMENT")
        }
        guard let orderOptions = buildOrderOptions(from: orderOptionsDict) else {
            return call.reject("customerName is required in orderOptions", "INVALID_ARGUMENT")
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
              let orderOptionsDict = call.getObject("orderOptions") else {
            return call.reject("redemptionCode and orderOptions are required", "INVALID_ARGUMENT")
        }
        guard let orderOptions = buildOrderOptions(from: orderOptionsDict) else {
            return call.reject("customerName is required in orderOptions", "INVALID_ARGUMENT")
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

        FlyBuy.Core.getInstance().orders.updateOrderState(
            orderID: orderID,
            state: state
        ) { order, error in
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
                orderID: orderID,
                customerState: customerState,
                spotIdentifier: spotIdentifier
            ) { order, error in
                if let error = error { return self.rejectWithError(call, error) }
                guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
                call.resolve(["order": self.serializeOrder(order)])
            }
        } else {
            FlyBuy.Core.getInstance().orders.updateCustomerState(
                orderID: orderID,
                customerState: customerState
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

        if let carType = call.getString("customerCarType") {
            builder.setCustomerCarType(carType)
        }
        if let carColor = call.getString("customerCarColor") {
            builder.setCustomerCarColor(carColor)
        }
        if let licensePlate = call.getString("customerLicensePlate") {
            builder.setCustomerLicensePlate(licensePlate)
        }
        if let handoffLocation = call.getString("handoffVehicleLocation") {
            builder.setHandoffVehicleLocation(handoffLocation)
        }

        FlyBuy.Core.getInstance().orders.updatePickupMethod(
            orderID: orderID,
            pickupMethodOptions: builder.build()
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
            orderID: orderID,
            rating: rating,
            comments: comments,
            categories: categories
        ) { order, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let order = order else { return call.reject("No order returned", "NOT_FOUND") }
            call.resolve(["order": self.serializeOrder(order)])
        }
    }

    // MARK: - Customer

    @objc func getCurrentCustomer(_ call: CAPPluginCall) {
        if let customer = FlyBuy.Core.getInstance().customer.current {
            call.resolve(["customer": serializeCustomer(customer)])
        } else {
            call.resolve(["customer": NSNull()])
        }
    }

    @objc func createCustomer(_ call: CAPPluginCall) {
        guard let infoDict = call.getObject("customerInfo") else {
            return call.reject("customerInfo is required", "INVALID_ARGUMENT")
        }
        let termsOfService = call.getBool("termsOfService") ?? false
        let ageVerification = call.getBool("ageVerification") ?? false

        FlyBuy.Core.getInstance().customer.create(
            buildCustomerInfo(from: infoDict),
            termsOfService: termsOfService,
            ageVerification: ageVerification
        ) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    @objc func createCustomerWithLogin(_ call: CAPPluginCall) {
        guard let infoDict = call.getObject("customerInfo"),
              let email = call.getString("email"),
              let password = call.getString("password") else {
            return call.reject("customerInfo, email, and password are required", "INVALID_ARGUMENT")
        }
        let termsOfService = call.getBool("termsOfService") ?? false
        let ageVerification = call.getBool("ageVerification") ?? false

        FlyBuy.Core.getInstance().customer.create(
            buildCustomerInfo(from: infoDict),
            email: email,
            password: password,
            termsOfService: termsOfService,
            ageVerification: ageVerification
        ) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    @objc func loginWithToken(_ call: CAPPluginCall) {
        guard let token = call.getString("token") else {
            return call.reject("token is required", "INVALID_ARGUMENT")
        }

        FlyBuy.Core.getInstance().customer.login(withToken: token) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    @objc func logoutCustomer(_ call: CAPPluginCall) {
        FlyBuy.Core.getInstance().customer.logout()
        call.resolve()
    }

    @objc func updateCustomer(_ call: CAPPluginCall) {
        guard let infoDict = call.getObject("customerInfo") else {
            return call.reject("customerInfo is required", "INVALID_ARGUMENT")
        }

        FlyBuy.Core.getInstance().customer.update(buildCustomerInfo(from: infoDict)) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    @objc func signUpCustomer(_ call: CAPPluginCall) {
        guard let email = call.getString("email"),
              let password = call.getString("password") else {
            return call.reject("email and password are required", "INVALID_ARGUMENT")
        }

        FlyBuy.Core.getInstance().customer.signUp(email, password) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    // MARK: - Sites

    @objc func fetchAllSites(_ call: CAPPluginCall) {
        FlyBuy.Core.getInstance().sites.fetchAll { sites, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve(["sites": (sites ?? []).map { self.serializeSite($0) }])
        }
    }

    @objc func fetchSitesByQuery(_ call: CAPPluginCall) {
        guard let query = call.getString("query") else {
            return call.reject("query is required", "INVALID_ARGUMENT")
        }

        FlyBuy.Core.getInstance().sites.fetch(query: query) { sites, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve(["sites": (sites ?? []).map { self.serializeSite($0) }])
        }
    }

    @objc func fetchSitesByRegion(_ call: CAPPluginCall) {
        guard let lat = call.getDouble("latitude"),
              let lng = call.getDouble("longitude"),
              let radius = call.getDouble("radiusMeters") else {
            return call.reject("latitude, longitude, and radiusMeters are required", "INVALID_ARGUMENT")
        }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            radius: radius,
            identifier: "flybuy-query-region"
        )

        FlyBuy.Core.getInstance().sites.fetch(query: nil, region: region) { sites, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve(["sites": (sites ?? []).map { self.serializeSite($0) }])
        }
    }

    @objc func fetchSiteByPartnerIdentifier(_ call: CAPPluginCall) {
        guard let partnerIdentifier = call.getString("partnerIdentifier") else {
            return call.reject("partnerIdentifier is required", "INVALID_ARGUMENT")
        }

        FlyBuy.Core.getInstance().sites.fetchByPartnerIdentifier(
            partnerIdentifier: partnerIdentifier
        ) { site, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let site = site else { return call.reject("Site not found", "NOT_FOUND") }
            call.resolve(["site": self.serializeSite(site)])
        }
    }

    // MARK: - Error Handling

    private func rejectWithError(_ call: CAPPluginCall, _ error: Error) {
        switch error {
        case let ordersError as OrdersManagerError:
            call.reject(
                ordersError.errorDescription ?? error.localizedDescription,
                "ORDERS_ERROR"
            )
        case let apiError as FlyBuyAPIError:
            call.reject(
                error.localizedDescription,
                "API_ERROR",
                error,
                ["statusCode": apiError.statusCodeInt]
            )
        case let commonError as FlyBuyError:
            call.reject(
                commonError.errorDescription ?? error.localizedDescription,
                "FLYBUY_ERROR"
            )
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

    private func serializeCustomer(_ customer: FlyBuyCustomer) -> [String: Any] {
        var dict: [String: Any] = ["token": customer.token]
        if let email = customer.emailAddress { dict["emailAddress"] = email }
        if let name = customer.name { dict["name"] = name }
        if let carType = customer.carType { dict["carType"] = carType }
        if let carColor = customer.carColor { dict["carColor"] = carColor }
        if let licensePlate = customer.licensePlate { dict["licensePlate"] = licensePlate }
        if let phone = customer.phone { dict["phone"] = phone }
        return dict
    }

    private func serializeSite(_ site: FlyBuySite) -> [String: Any] {
        var dict: [String: Any] = ["id": site.id]
        if let name = site.name { dict["name"] = name }
        if let partnerIdentifier = site.partnerIdentifier { dict["partnerIdentifier"] = partnerIdentifier }
        if let streetAddress = site.streetAddress { dict["streetAddress"] = streetAddress }
        if let fullAddress = site.fullAddress { dict["fullAddress"] = fullAddress }
        if let locality = site.locality { dict["locality"] = locality }
        if let region = site.region { dict["region"] = region }
        if let country = site.country { dict["country"] = country }
        if let postalCode = site.postalCode { dict["postalCode"] = postalCode }
        if let lat = site.latitude { dict["latitude"] = lat }
        if let lng = site.longitude { dict["longitude"] = lng }
        if let instructions = site.instructions { dict["instructions"] = instructions }
        if let description = site.descriptionText { dict["descriptionText"] = description }
        if let coverPhoto = site.coverPhotoURL { dict["coverPhotoURL"] = coverPhoto }
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

    private func buildCustomerInfo(from dict: [String: Any]) -> CustomerInfo {
        return CustomerInfo(
            name: dict["name"] as? String ?? "",
            carType: dict["carType"] as? String,
            carColor: dict["carColor"] as? String,
            licensePlate: dict["licensePlate"] as? String,
            phone: dict["phone"] as? String ?? ""
        )
    }
}

    // MARK: - Notify

    @objc func updateCustomTemplateContent(_ call: CAPPluginCall) {
        guard let content = call.getObject("content") else {
            return call.reject("content is required", "INVALID_ARGUMENT")
        }

        var templateContent: [String: String] = [:]
        for key in content.keys {
            if let value = content[key] as? String {
                templateContent[key] = value
            }
        }

        FlyBuyNotify.Manager.shared.updateCustomTemplateContent(templateContent)
        call.resolve()
    }

    // MARK: - Deep Links

    @objc func parseLink(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString) else {
            return call.reject("url is required", "INVALID_ARGUMENT")
        }

        let linkDetails = FlyBuy.Links.parse(url: url)

        var result: [String: Any] = [
            "url": linkDetails.url.absoluteString,
            "type": serializeLinkType(linkDetails.type)
        ]

        if let params = linkDetails.params {
            result["params"] = params
        }

        call.resolve(result)
    }

    private func serializeLinkType(_ type: FlyBuy.LinkType) -> String {
        switch type {
        case .dineIn:     return "dineIn"
        case .redemption: return "redemption"
        default:          return "other"
        }
    }