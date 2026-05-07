import Capacitor
import CoreLocation
import FlyBuy

@objc(FlybuyPlugin)
public class FlybuyPlugin: CAPPlugin {

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

    func serializeCustomer(_ customer: FlyBuyCustomer) -> [String: Any] {
        var dict: [String: Any] = ["token": customer.token]
        if let email = customer.emailAddress { dict["emailAddress"] = email }
        if let name = customer.name { dict["name"] = name }
        if let carType = customer.carType { dict["carType"] = carType }
        if let carColor = customer.carColor { dict["carColor"] = carColor }
        if let licensePlate = customer.licensePlate { dict["licensePlate"] = licensePlate }
        if let phone = customer.phone { dict["phone"] = phone }
        return dict
    }

    func serializeSite(_ site: FlyBuySite) -> [String: Any] {
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