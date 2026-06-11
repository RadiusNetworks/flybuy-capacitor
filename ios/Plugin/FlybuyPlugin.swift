import Capacitor
import CoreLocation
import FlyBuy
import FlyBuyPickup

@objc(FlybuyPlugin)
public class FlybuyPlugin: CAPPlugin {

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

    // MARK: - Customer

    @objc func getCurrentCustomer(_ call: CAPPluginCall) {
        if let customer = getInstance(call).customer.current {
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

        getInstance(call).customer.create(
            buildCustomerInfo(from: infoDict),
            termsOfService: termsOfService,
            ageVerification: ageVerification
        ) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    @objc func login(_ call: CAPPluginCall) {
        guard let email = call.getString("email"),
              let password = call.getString("password") else {
            return call.reject("email and password are required", "INVALID_ARGUMENT")
        }
        getInstance(call).customer.login(
            emailAddress: email,
            password: password
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
        getInstance(call).customer.loginWithToken(token: token) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    @objc func logout(_ call: CAPPluginCall) {
        getInstance(call).customer.logout()
        call.resolve()
    }

    @objc func updateCustomer(_ call: CAPPluginCall) {
        guard let infoDict = call.getObject("customerInfo") else {
            return call.reject("customerInfo is required", "INVALID_ARGUMENT")
        }
        getInstance(call).customer.update(buildCustomerInfo(from: infoDict)) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    @objc func signUp(_ call: CAPPluginCall) {
        guard let email = call.getString("email"),
              let password = call.getString("password") else {
            return call.reject("email and password are required", "INVALID_ARGUMENT")
        }
        getInstance(call).customer.signUp(emailAddress: email, password: password) { customer, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let customer = customer else { return call.reject("No customer returned", "NOT_FOUND") }
            call.resolve(["customer": self.serializeCustomer(customer)])
        }
    }

    // MARK: - Sites

    @objc func fetchSitesByRegion(_ call: CAPPluginCall) {
        guard let lat = call.getDouble("latitude"),
              let lng = call.getDouble("longitude"),
              let radius = call.getDouble("radiusMeters") else {
            return call.reject("latitude, longitude, and radiusMeters are required", "INVALID_ARGUMENT")
        }
        let region = FlyBuyCircularRegion(
            latitude: lat,
            longitude: lng,
            radius: radius,
            identifier: "flybuy-query-region"
        )
        getInstance(call).sites.fetch(region: region, options: SiteOptions(operationalStatus: "operational", page: nil, per: nil)) { sites, _, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve(["sites": (sites ?? []).map { self.serializeSite($0) }])
        }
    }

    @objc func fetchSiteByPartnerIdentifier(_ call: CAPPluginCall) {
        guard let partnerIdentifier = call.getString("partnerIdentifier") else {
            return call.reject("partnerIdentifier is required", "INVALID_ARGUMENT")
        }
        getInstance(call).sites.fetchByPartnerIdentifier(
            partnerIdentifier: partnerIdentifier,
            options: SiteOptions(operationalStatus: "operational", page: nil, per: nil)
        ) { site, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let site = site else { return call.reject("Site not found", "NOT_FOUND") }
            call.resolve(["site": self.serializeSite(site)])
        }
    }

    @objc func fetchSitesNearPlace(_ call: CAPPluginCall) {
        guard let placeDict = call.getObject("place"),
              let radius = call.getDouble("radius") else {
            return call.reject("place and radius are required", "INVALID_ARGUMENT")
        }
        let place = buildPlace(from: placeDict)
        getInstance(call).sites.fetchNear(
            place: place,
            radius: radius,
            options: SiteOptions(operationalStatus: "operational", page: nil, per: nil)
        ) { sites, _, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve(["sites": (sites ?? []).map { self.serializeSite($0) }])
        }
    }

    // MARK: - Places

    @objc func placesSuggest(_ call: CAPPluginCall) {
        guard let query = call.getString("query") else {
            return call.reject("query is required", "INVALID_ARGUMENT")
        }
        let optionsDict = call.getObject("options")
        let lat = optionsDict?["latitude"] as? Double ?? 0.0
        let lng = optionsDict?["longitude"] as? Double ?? 0.0
        let options = PlaceSuggestionOptions(
            latitude: lat,
            longitude: lng,
            types: [],
            countryCodes: []
        )
        getInstance(call).places.suggest(query: query, options: options) { places, error in
            if let error = error { return self.rejectWithError(call, error) }
            call.resolve(["places": (places ?? []).map { self.serializePlace($0) }])
        }
    }

    @objc func placesRetrieve(_ call: CAPPluginCall) {
        guard let placeDict = call.getObject("place") else {
            return call.reject("place is required", "INVALID_ARGUMENT")
        }
        let place = buildPlace(from: placeDict)
        getInstance(call).places.retrieve(place: place) { coordinate, error in
            if let error = error { return self.rejectWithError(call, error) }
            guard let coordinate = coordinate else { return call.reject("Place not found", "NOT_FOUND") }
            call.resolve(["place": [
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude
            ]])
        }
    }

    // MARK: - Deep Links

    @objc func parseLink(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString) else {
            return call.reject("url is required", "INVALID_ARGUMENT")
        }
        let linkDetails = FlyBuy.Links.parse(url: url)
        let linkType: String
        switch linkDetails.type {
        case .dineIn:     linkType = "dineIn"
        case .redemption: linkType = "redemption"
        default:          linkType = "other"
        }
        var result: [String: Any] = [
            "url": linkDetails.url,
            "type": linkType
        ]
        if !linkDetails.params.isEmpty {
            result["params"] = linkDetails.params
        }
        call.resolve(result)
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

    func rejectWithError(_ call: CAPPluginCall, _ error: Error) {
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

    func serializeCustomer(_ customer: FlyBuy.Customer) -> [String: Any] {
        var dict: [String: Any] = ["token": customer.token]
        if let email = customer.emailAddress { dict["emailAddress"] = email }
        dict["name"] = customer.info.name
        if let carType = customer.info.carType { dict["carType"] = carType }
        if let carColor = customer.info.carColor { dict["carColor"] = carColor }
        if let licensePlate = customer.info.licensePlate { dict["licensePlate"] = licensePlate }
        if let phone = customer.info.phone { dict["phone"] = phone }
        return dict
    }

    func serializeSite(_ site: FlyBuy.Site) -> [String: Any] {
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

    func serializePlace(_ place: FlyBuy.Place) -> [String: Any] {
        var dict: [String: Any] = [
            "name": place.name,
            "placeID": place.id
        ]
        if let address = place.address { dict["address"] = address }
        return dict
    }

    func serializeOrder(_ order: Order) -> [String: Any] {
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

    func buildPlace(from dict: [String: Any]) -> FlyBuy.Place {
        return FlyBuy.Place(
            id: dict["placeID"] as? String ?? "",
            name: dict["name"] as? String ?? "",
            placeFormatted: dict["address"] as? String ?? "",
            address: dict["address"] as? String,
            distance: 0.0
        )
    }

    func buildCustomerInfo(from dict: [String: Any]) -> CustomerInfo {
        return CustomerInfo(
            name: dict["name"] as? String ?? "",
            carType: dict["carType"] as? String,
            carColor: dict["carColor"] as? String,
            licensePlate: dict["licensePlate"] as? String,
            phone: dict["phone"] as? String ?? ""
        )
    }

    func buildOrderOptions(from dict: [String: Any]) -> OrderOptions? {
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