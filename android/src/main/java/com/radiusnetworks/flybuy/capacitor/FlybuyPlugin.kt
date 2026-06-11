package com.radiusnetworks.flybuy.capacitor

import com.getcapacitor.JSArray
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
import com.radiusnetworks.flybuy.sdk.data.room.domain.Order
import com.radiusnetworks.flybuy.sdk.data.room.domain.PickupWindow
import com.radiusnetworks.flybuy.sdk.data.room.domain.Site
import com.radiusnetworks.flybuy.sdk.data.room.domain.open
import com.radiusnetworks.flybuy.sdk.data.places.Place
import com.radiusnetworks.flybuy.sdk.data.places.PlaceLocation
import com.radiusnetworks.flybuy.sdk.manager.builder.OrderOptions
import com.radiusnetworks.flybuy.sdk.manager.builder.PickupMethodOptions
import com.radiusnetworks.flybuy.sdk.manager.builder.PlaceSuggestionOptions
import com.radiusnetworks.flybuy.sdk.pickup.data.error.PickupError
import java.time.Instant

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

    // ── Orders ────────────────────────────────────────────────────────────────

    @PluginMethod
    fun fetchOrders(call: PluginCall) {
        getInstance(call).orders.fetch { orders, sdkError ->
            if (sdkError != null) return@fetch rejectWithError(call, sdkError)
            val ret = JSObject()
            ret.put("orders", (orders ?: emptyList()).map { serializeOrder(it) }.toJSArray())
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun getOrders(call: PluginCall) {
        val filter = call.getString("filter") ?: "all"
        val instance = getInstance(call)
        val orders = when (filter) {
            "open" -> instance.orders.open
            else   -> instance.orders.all
        }
        val ret = JSObject()
        ret.put("orders", orders.map { serializeOrder(it) }.toJSArray())
        call.resolve(ret)
    }

    @PluginMethod
    fun fetchOrderByRedemptionCode(call: PluginCall) {
        val redemptionCode = call.getString("redemptionCode")
            ?: return call.reject("redemptionCode is required", "INVALID_ARGUMENT")

        getInstance(call).orders.fetch(redemptionCode) { order, sdkError ->
            if (sdkError != null) return@fetch rejectWithError(call, sdkError)
            if (order == null) return@fetch call.reject("No order found", "NOT_FOUND")
            val ret = JSObject()
            ret.put("order", serializeOrder(order))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun createOrderBySiteID(call: PluginCall) {
        val siteID = call.getInt("siteID")
            ?: return call.reject("siteID is required", "INVALID_ARGUMENT")
        val orderOptionsObj = call.getObject("orderOptions")
            ?: return call.reject("orderOptions is required", "INVALID_ARGUMENT")
        val orderOptions = buildOrderOptions(orderOptionsObj)
            ?: return call.reject("customerName is required in orderOptions", "INVALID_ARGUMENT")

        getInstance(call).orders.create(siteID = siteID, orderOptions = orderOptions) { order, sdkError ->
            if (sdkError != null) return@create rejectWithError(call, sdkError)
            if (order == null) return@create call.reject("No order returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("order", serializeOrder(order))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun createOrderBySitePartnerIdentifier(call: PluginCall) {
        val sitePartnerIdentifier = call.getString("sitePartnerIdentifier")
            ?: return call.reject("sitePartnerIdentifier is required", "INVALID_ARGUMENT")
        val orderOptionsObj = call.getObject("orderOptions")
            ?: return call.reject("orderOptions is required", "INVALID_ARGUMENT")
        val orderOptions = buildOrderOptions(orderOptionsObj)
            ?: return call.reject("customerName is required in orderOptions", "INVALID_ARGUMENT")

        getInstance(call).orders.create(
            sitePartnerIdentifier = sitePartnerIdentifier,
            orderOptions = orderOptions
        ) { order, sdkError ->
            if (sdkError != null) return@create rejectWithError(call, sdkError)
            if (order == null) return@create call.reject("No order returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("order", serializeOrder(order))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun claimOrder(call: PluginCall) {
        val redemptionCode = call.getString("redemptionCode")
            ?: return call.reject("redemptionCode is required", "INVALID_ARGUMENT")
        val orderOptionsObj = call.getObject("orderOptions")
            ?: return call.reject("orderOptions is required", "INVALID_ARGUMENT")
        val orderOptions = buildOrderOptions(orderOptionsObj)
            ?: return call.reject("customerName is required in orderOptions", "INVALID_ARGUMENT")

        getInstance(call).orders.claim(redemptionCode, orderOptions) { order, sdkError ->
            if (sdkError != null) return@claim rejectWithError(call, sdkError)
            if (order == null) return@claim call.reject("No order returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("order", serializeOrder(order))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun updateOrderState(call: PluginCall) {
        val orderID = call.getInt("orderID")
            ?: return call.reject("orderID is required", "INVALID_ARGUMENT")
        val state = call.getString("state")
            ?: return call.reject("state is required", "INVALID_ARGUMENT")

        getInstance(call).orders.updateState(orderID, state) { order, sdkError ->
            if (sdkError != null) return@updateState rejectWithError(call, sdkError)
            if (order == null) return@updateState call.reject("No order returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("order", serializeOrder(order))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun updateOrderCustomerState(call: PluginCall) {
        val orderID = call.getInt("orderID")
            ?: return call.reject("orderID is required", "INVALID_ARGUMENT")
        val customerState = call.getString("customerState")
            ?: return call.reject("customerState is required", "INVALID_ARGUMENT")
        val spotIdentifier = call.getString("spotIdentifier")

        if (spotIdentifier != null) {
            getInstance(call).orders.updateCustomerState(orderID, customerState, spotIdentifier) { order, sdkError ->
                if (sdkError != null) return@updateCustomerState rejectWithError(call, sdkError)
                if (order == null) return@updateCustomerState call.reject("No order returned", "NOT_FOUND")
                val ret = JSObject()
                ret.put("order", serializeOrder(order))
                call.resolve(ret)
            }
        } else {
            getInstance(call).orders.updateCustomerState(orderID, customerState) { order, sdkError ->
                if (sdkError != null) return@updateCustomerState rejectWithError(call, sdkError)
                if (order == null) return@updateCustomerState call.reject("No order returned", "NOT_FOUND")
                val ret = JSObject()
                ret.put("order", serializeOrder(order))
                call.resolve(ret)
            }
        }
    }

    @PluginMethod
    fun updatePickupMethod(call: PluginCall) {
        val orderID = call.getInt("orderID")
            ?: return call.reject("orderID is required", "INVALID_ARGUMENT")
        val pickupType = call.getString("pickupType")
            ?: return call.reject("pickupType is required", "INVALID_ARGUMENT")

        val builder = PickupMethodOptions.Builder(pickupType)
        call.getString("customerCarType")?.let { builder.setCustomerCarType(it) }
        call.getString("customerCarColor")?.let { builder.setCustomerCarColor(it) }
        call.getString("customerLicensePlate")?.let { builder.setCustomerLicensePlate(it) }
        call.getString("handoffVehicleLocation")?.let { builder.setHandoffVehicleLocation(it) }

        getInstance(call).orders.updatePickupMethod(orderID, builder.build()) { order, sdkError ->
            if (sdkError != null) return@updatePickupMethod rejectWithError(call, sdkError)
            if (order == null) return@updatePickupMethod call.reject("No order returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("order", serializeOrder(order))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun rateOrder(call: PluginCall) {
        val orderID = call.getInt("orderID")
            ?: return call.reject("orderID is required", "INVALID_ARGUMENT")
        val rating = call.getInt("rating")
            ?: return call.reject("rating is required", "INVALID_ARGUMENT")
        val comments = call.getString("comments")
        val categoriesArray = call.getArray("categories")
        val categories = mutableListOf<String>()
        if (categoriesArray != null) {
            for (i in 0 until categoriesArray.length()) {
                categories.add(categoriesArray.getString(i))
            }
        }

        getInstance(call).orders.rateOrder(
            orderId = orderID,
            rating = rating,
            comments = comments,
            categories = categories
        ) { order, sdkError ->
            if (sdkError != null) return@rateOrder rejectWithError(call, sdkError)
            if (order == null) return@rateOrder call.reject("No order returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("order", serializeOrder(order))
            call.resolve(ret)
        }
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

    internal fun serializeOrder(order: Order): JSObject {
        return JSObject().apply {
            put("id", order.id)
            put("state", order.state)
            put("customerState", order.customerState)
            put("isOpen", order.open())
            put("siteID", order.site.id)
            order.partnerIdentifier?.let { put("partnerIdentifier", it) }
            order.partnerIdentifierForCrew?.let { put("partnerIdentifierForCrew", it) }
            order.partnerIdentifierForCustomer?.let { put("partnerIdentifierForCustomer", it) }
            order.redeemedAt?.let { put("redeemedAt", it.toString()) }
            order.customerRatingValue?.let { put("customerRatingValue", it) }
            put("spotIdentifierEntryEnabled", order.spotIdentifierEntryEnabled)
            put("spotIdentifierInputType", order.spotIdentifierInputType.name)
            order.pickupType?.let { put("pickupType", it) }
            put("customerName", order.customer.name)
            put("customerCarType", order.customer.carType)
            put("customerCarColor", order.customer.carColor)
            put("customerCarPlate", order.customer.licensePlate)
            order.etaAt?.let { put("etaAtStop", it.toString()) }
            order.pickupWindow?.let { window ->
                val windowObj = JSObject()
                windowObj.put("start", window.start.toString())
                window.end?.let { windowObj.put("end", it.toString()) }
                put("pickupWindow", windowObj)
            }
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

    private fun buildOrderOptions(obj: JSObject): OrderOptions? {
        val customerName = obj.getString("customerName") ?: return null
        val builder = OrderOptions.Builder(customerName = customerName)

        obj.getString("customerPhone")?.let { builder.setCustomerPhone(it) }
        obj.getString("customerCarColor")?.let { builder.setCustomerCarColor(it) }
        obj.getString("customerCarType")?.let { builder.setCustomerCarType(it) }
        obj.getString("customerCarPlate")?.let { builder.setCustomerCarPlate(it) }
        obj.getString("partnerIdentifier")?.let { builder.setPartnerIdentifier(it) }
        obj.getString("partnerIdentifierForCrew")?.let { builder.setPartnerIdentifierForCrew(it) }
        obj.getString("partnerIdentifierForCustomer")?.let { builder.setPartnerIdentifierForCustomer(it) }
        obj.getString("pickupType")?.let { builder.setPickupType(it) }
        obj.getString("state")?.let { builder.setState(it) }
        obj.getString("transportMode")?.let { builder.setTransportMode(it) }
        obj.getString("handoffVehicleLocation")?.let { builder.setHandoffVehicleLocation(it) }

        val loyaltyId = obj.getString("loyaltyIdentifier")
        val loyaltyProvider = obj.getString("loyaltyProvider")
        if (loyaltyId != null && loyaltyProvider != null) {
            builder.setLoyaltyInfo(loyaltyId, loyaltyProvider)
        }

        if (obj.has("disableOrderFire")) builder.setDisableOrderFire(obj.getBool("disableOrderFire") ?: false)
        if (obj.has("disablePromiseTimeScheduling")) builder.setDisablePromiseTimeScheduling(obj.getBool("disablePromiseTimeScheduling") ?: false)
        if (obj.has("orderFireMakeIntervalSeconds")) builder.setOrderFireMakeIntervalSeconds(obj.getInteger("orderFireMakeIntervalSeconds") ?: 0)

        obj.getJSObject("pickupWindow")?.let { windowObj ->
            val startStr = windowObj.getString("start")
            if (startStr != null) {
                val startInstant = Instant.parse(startStr)
                val endStr = windowObj.getString("end")
                val endInstant = if (endStr != null) Instant.parse(endStr) else null
                builder.setPickupWindow(
                    if (endInstant != null) PickupWindow(startInstant, endInstant)
                    else PickupWindow(startInstant)
                )
            }
        }

        return builder.build()
    }

    private fun List<JSObject>.toJSArray(): JSArray {
        val arr = JSArray()
        forEach { arr.put(it) }
        return arr
    }
}