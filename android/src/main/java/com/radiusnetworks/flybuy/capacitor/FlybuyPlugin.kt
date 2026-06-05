package com.radiusnetworks.flybuy.capacitor

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.radiusnetworks.flybuy.sdk.FlyBuyCore
import com.radiusnetworks.flybuy.sdk.FlyBuyLinks
import com.radiusnetworks.flybuy.sdk.data.common.GenericSdkError
import com.radiusnetworks.flybuy.sdk.data.common.SdkError
import com.radiusnetworks.flybuy.sdk.data.customer.CustomerInfo
import com.radiusnetworks.flybuy.sdk.data.location.CircularRegion
import com.radiusnetworks.flybuy.sdk.data.room.domain.Customer
import com.radiusnetworks.flybuy.sdk.data.places.Place
import com.radiusnetworks.flybuy.sdk.data.places.PlaceLocation
import com.radiusnetworks.flybuy.sdk.manager.builder.PlaceSuggestionOptions
import com.radiusnetworks.flybuy.sdk.data.room.domain.Site
import com.radiusnetworks.flybuy.sdk.pickup.data.error.PickupError

@CapacitorPlugin(name = "Flybuy")
class FlybuyPlugin : Plugin() {

    // ── Instance Helper ───────────────────────────────────────────────────────

    private fun getInstance(call: PluginCall) =
        FlyBuyCore.getInstance(call.getString("appAuthId"))

    // ── Customer ─────────────────────────────────────────────────────────────

    @PluginMethod
    fun getCurrentCustomer(call: PluginCall) {
        val ret = JSObject()
        val customer = getInstance(call).customer.current
        if (customer != null) {
            ret.put("customer", serializeCustomer(customer))
        } else {
            ret.put("customer", JSObject.NULL)
        }
        call.resolve(ret)
    }

    @PluginMethod
    fun createCustomer(call: PluginCall) {
        val infoObj = call.getObject("customerInfo")
            ?: return call.reject("customerInfo is required", "INVALID_ARGUMENT")
        val termsOfService = call.getBoolean("termsOfService") ?: false
        val ageVerification = call.getBoolean("ageVerification") ?: false

        getInstance(call).customer.create(
            buildCustomerInfo(infoObj),
            termsOfService = termsOfService,
            ageVerification = ageVerification
        ) { customer, sdkError ->
            if (sdkError != null) return@create rejectWithError(call, sdkError)
            if (customer == null) return@create call.reject("No customer returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("customer", serializeCustomer(customer))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun login(call: PluginCall) {
        val email = call.getString("email")
            ?: return call.reject("email is required", "INVALID_ARGUMENT")
        val password = call.getString("password")
            ?: return call.reject("password is required", "INVALID_ARGUMENT")

        getInstance(call).customer.login(email, password) { customer, sdkError ->
            if (sdkError != null) return@login rejectWithError(call, sdkError)
            if (customer == null) return@login call.reject("No customer returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("customer", serializeCustomer(customer))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun loginWithToken(call: PluginCall) {
        val token = call.getString("token")
            ?: return call.reject("token is required", "INVALID_ARGUMENT")

        getInstance(call).customer.loginWithToken(token) { customer, sdkError ->
            if (sdkError != null) return@loginWithToken rejectWithError(call, sdkError)
            if (customer == null) return@loginWithToken call.reject("No customer returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("customer", serializeCustomer(customer))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun logout(call: PluginCall) {
        getInstance(call).customer.logout()
        call.resolve()
    }

    @PluginMethod
    fun updateCustomer(call: PluginCall) {
        val infoObj = call.getObject("customerInfo")
            ?: return call.reject("customerInfo is required", "INVALID_ARGUMENT")

        getInstance(call).customer.update(buildCustomerInfo(infoObj)) { customer, sdkError ->
            if (sdkError != null) return@update rejectWithError(call, sdkError)
            if (customer == null) return@update call.reject("No customer returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("customer", serializeCustomer(customer))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun signUp(call: PluginCall) {
        val email = call.getString("email")
            ?: return call.reject("email is required", "INVALID_ARGUMENT")
        val password = call.getString("password")
            ?: return call.reject("password is required", "INVALID_ARGUMENT")

        getInstance(call).customer.signUp(email, password) { customer, sdkError ->
            if (sdkError != null) return@signUp rejectWithError(call, sdkError)
            if (customer == null) return@signUp call.reject("No customer returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("customer", serializeCustomer(customer))
            call.resolve(ret)
        }
    }

    // ── Sites ─────────────────────────────────────────────────────────────────

    @PluginMethod
    fun fetchSitesByRegion(call: PluginCall) {
        val latitude = call.getDouble("latitude")
            ?: return call.reject("latitude is required", "INVALID_ARGUMENT")
        val longitude = call.getDouble("longitude")
            ?: return call.reject("longitude is required", "INVALID_ARGUMENT")
        val radiusMeters = call.getDouble("radiusMeters")
            ?: return call.reject("radiusMeters is required", "INVALID_ARGUMENT")

        val region = CircularRegion(
            latitude = latitude,
            longitude = longitude,
            radius = radiusMeters.toFloat()
        )
        getInstance(call).sites.fetch(region, null) { sites, _, sdkError ->
            if (sdkError != null) return@fetch rejectWithError(call, sdkError)
            val ret = JSObject()
            ret.put("sites", (sites ?: emptyList()).map { serializeSite(it) }.toJSArray())
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun fetchSiteByPartnerIdentifier(call: PluginCall) {
        val partnerIdentifier = call.getString("partnerIdentifier")
            ?: return call.reject("partnerIdentifier is required", "INVALID_ARGUMENT")

        getInstance(call).sites.fetchByPartnerIdentifier(partnerIdentifier, null) { site, sdkError ->
            if (sdkError != null) return@fetchByPartnerIdentifier rejectWithError(call, sdkError)
            if (site == null) return@fetchByPartnerIdentifier call.reject("Site not found", "NOT_FOUND")
            val ret = JSObject()
            ret.put("site", serializeSite(site))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun fetchSitesNearPlace(call: PluginCall) {
        val placeObj = call.getObject("place")
            ?: return call.reject("place is required", "INVALID_ARGUMENT")
        val radius = call.getDouble("radius")
            ?: return call.reject("radius is required", "INVALID_ARGUMENT")

        val place = buildPlace(placeObj)
        getInstance(call).sites.fetchNear(place, radius.toFloat(), null) { sites, _, sdkError ->
            if (sdkError != null) return@fetchNear rejectWithError(call, sdkError)
            val ret = JSObject()
            ret.put("sites", (sites ?: emptyList()).map { serializeSite(it) }.toJSArray())
            call.resolve(ret)
        }
    }

    // ── Places ────────────────────────────────────────────────────────────────

    @PluginMethod
    fun placesSuggest(call: PluginCall) {
        val query = call.getString("query")
            ?: return call.reject("query is required", "INVALID_ARGUMENT")
        val optionsObj = call.getObject("options")
        val latitude = optionsObj?.getDouble("latitude")
        val longitude = optionsObj?.getDouble("longitude")

        val suggestionOptionsBuilder = PlaceSuggestionOptions.Builder()
        if (latitude != null && longitude != null) {
            suggestionOptionsBuilder.setProximity(latitude, longitude)
        }
        val suggestionOptions = suggestionOptionsBuilder.build()
        getInstance(call).places.suggest(query, suggestionOptions) { places, sdkError ->
            if (sdkError != null) return@suggest rejectWithError(call, sdkError)
            val ret = JSObject()
            ret.put("places", (places ?: emptyList()).map { serializePlace(it) }.toJSArray())
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun placesRetrieve(call: PluginCall) {
        val placeObj = call.getObject("place")
            ?: return call.reject("place is required", "INVALID_ARGUMENT")

        val place = buildPlace(placeObj)
        getInstance(call).places.retrieve(place) { resolvedPlace, sdkError ->
            if (sdkError != null) return@retrieve rejectWithError(call, sdkError)
            if (resolvedPlace == null) return@retrieve call.reject("Place not found", "NOT_FOUND")
            val ret = JSObject()
            ret.put("place", serializePlaceLocation(resolvedPlace))
            call.resolve(ret)
        }
    }

    // ── Deep Links ────────────────────────────────────────────────────────────

    @PluginMethod
    fun parseLink(call: PluginCall) {
        val url = call.getString("url")
            ?: return call.reject("url is required", "INVALID_ARGUMENT")

        val linkDetails = FlyBuyLinks.parse(url)
        val ret = JSObject().apply {
            put("url", linkDetails.url)
            put("type", when (linkDetails.type.name.lowercase()) {
                "dinein" -> "dineIn"
                "redemption" -> "redemption"
                else -> "other"
            })
            val paramsObj = JSObject()
            linkDetails.params.entries.forEach { entry -> paramsObj.put(entry.key, entry.value) }
            put("params", paramsObj)
        }
        call.resolve(ret)
    }

    // ── Error Handling ────────────────────────────────────────────────────────

    internal fun rejectWithError(call: PluginCall, sdkError: SdkError) {
        when (sdkError) {
            is PickupError -> call.reject(sdkError.userError(), "PICKUP_ERROR")
            is GenericSdkError<*> -> call.reject(sdkError.userError(), "SDK_ERROR")
            else -> {
                val data = JSObject()
                data.put("statusCode", sdkError.code)
                call.reject(sdkError.userError(), "API_ERROR", null, data)
            }
        }
    }

    // ── Serializers ───────────────────────────────────────────────────────────

    private fun serializeCustomer(customer: Customer): JSObject {
        return JSObject().apply {
            put("token", customer.apiToken)
            customer.email?.let { put("emailAddress", it) }
            put("name", customer.name)
            put("carType", customer.carType)
            put("carColor", customer.carColor)
            put("licensePlate", customer.licensePlate)
            put("phone", customer.phone)
        }
    }

    internal fun serializeSite(site: Site): JSObject {
        return JSObject().apply {
            put("id", site.id)
            site.name?.let { put("name", it) }
            site.partnerIdentifier?.let { put("partnerIdentifier", it) }
            site.streetAddress?.let { put("streetAddress", it) }
            site.fullAddress?.let { put("fullAddress", it) }
            site.locality?.let { put("locality", it) }
            site.region?.let { put("region", it) }
            site.country?.let { put("country", it) }
            site.postalCode?.let { put("postalCode", it) }
            site.latitude?.let { put("latitude", it) }
            site.longitude?.let { put("longitude", it) }
            site.instructions?.let { put("instructions", it) }
            site.description?.let { put("descriptionText", it) }
            site.coverPhotoUrl?.let { put("coverPhotoURL", it) }
        }
    }

    internal fun serializePlace(place: Place): JSObject {
        return JSObject().apply {
            put("name", place.name)
            put("address", place.address ?: "")
            put("placeID", place.id)
            place.distance?.let { put("distance", it) }
        }
    }

    internal fun serializePlaceLocation(location: PlaceLocation): JSObject {
        return JSObject().apply {
            put("latitude", location.latitude)
            put("longitude", location.longitude)
        }
    }

    internal fun buildCustomerInfo(obj: JSObject): CustomerInfo {
        return CustomerInfo(
            name = obj.getString("name") ?: "",
            carType = obj.getString("carType") ?: "",
            carColor = obj.getString("carColor") ?: "",
            licensePlate = obj.getString("licensePlate") ?: "",
            phone = obj.getString("phone") ?: ""
        )
    }

    private fun buildPlace(obj: JSObject): Place {
        return Place(
            name = obj.getString("name") ?: "",
            id = obj.getString("placeID") ?: "",
            placeFormatted = obj.getString("address") ?: "",
            address = obj.getString("address") ?: "",
            distance = null
        )
    }

    private fun List<JSObject>.toJSArray(): com.getcapacitor.JSArray {
        val arr = com.getcapacitor.JSArray()
        forEach { arr.put(it) }
        return arr
    }
}