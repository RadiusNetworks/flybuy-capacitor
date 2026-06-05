import Capacitor
import CoreLocation
import FlyBuy

@objc(FlybuyPlugin)
public class FlybuyPlugin: CAPPlugin {

    // MARK: - Instance Helper

    private func getInstance(_ call: CAPPluginCall) -> FlyBuy.Instance {
        let appAuthId = call.getString("appAuthId")
        return try! FlyBuy.Core.getInstance(forAppAuthId: appAuthId)
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
}