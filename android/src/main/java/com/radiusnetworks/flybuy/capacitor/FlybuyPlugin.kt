package com.radiusnetworks.flybuy.capacitor

import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.radiusnetworks.flybuy.sdk.FlyBuyCore
import com.radiusnetworks.flybuy.sdk.data.common.GenericSdkError
import com.radiusnetworks.flybuy.sdk.data.common.SdkError
import com.radiusnetworks.flybuy.sdk.data.customer.CustomerInfo
import com.radiusnetworks.flybuy.sdk.data.location.CircularRegion
import com.radiusnetworks.flybuy.sdk.data.room.domain.Customer
import com.radiusnetworks.flybuy.sdk.data.room.domain.Order
import com.radiusnetworks.flybuy.sdk.data.room.domain.PickupWindow
import com.radiusnetworks.flybuy.sdk.data.room.domain.Site
import com.radiusnetworks.flybuy.sdk.data.room.domain.open
import com.radiusnetworks.flybuy.sdk.manager.builder.OrderOptions
import com.radiusnetworks.flybuy.sdk.manager.builder.PickupMethodOptions
import com.radiusnetworks.flybuy.sdk.pickup.data.error.PickupError
import java.time.Instant

@CapacitorPlugin(name = "Flybuy")
class FlybuyPlugin : Plugin() {

    // ── Orders ───────────────────────────────────────────────────────────────

    @PluginMethod
    fun fetchOrders(call: PluginCall) {
        FlyBuyCore.getInstance().orders.fetch { orders, sdkError ->
            if (sdkError != null) return@fetch rejectWithError(call, sdkError)
            val ret = JSObject()
            ret.put("orders", (orders ?: emptyList()).map { serializeOrder(it) }.toJSArray())
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun getOrders(call: PluginCall) {
        val filter = call.getString("filter") ?: "all"
        val orders = when (filter) {
            "open" -> FlyBuyCore.getInstance().orders.open
            else   -> FlyBuyCore.getInstance().orders.all
        }
        val ret = JSObject()
        ret.put("orders", (orders ?: emptyList()).map { serializeOrder(it) }.toJSArray())
        call.resolve(ret)
    }

    @PluginMethod
    fun fetchOrderByRedemptionCode(call: PluginCall) {
        val redemptionCode = call.getString("redemptionCode")
            ?: return call.reject("redemptionCode is required", "INVALID_ARGUMENT")

        FlyBuyCore.getInstance().orders.fetch(redemptionCode) { order, sdkError ->
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

        FlyBuyCore.getInstance().orders.create(siteID = siteID, orderOptions = orderOptions) { order, sdkError ->
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

        FlyBuyCore.getInstance().orders.create(
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

        FlyBuyCore.getInstance().orders.claim(redemptionCode, orderOptions) { order, sdkError ->
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

        FlyBuyCore.getInstance().orders.updateState(orderID, state) { order, sdkError ->
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
            FlyBuyCore.getInstance().orders.updateCustomerState(orderID, customerState, spotIdentifier) { order, sdkError ->
                if (sdkError != null) return@updateCustomerState rejectWithError(call, sdkError)
                if (order == null) return@updateCustomerState call.reject("No order returned", "NOT_FOUND")
                val ret = JSObject()
                ret.put("order", serializeOrder(order))
                call.resolve(ret)
            }
        } else {
            FlyBuyCore.getInstance().orders.updateCustomerState(orderID, customerState) { order, sdkError ->
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

        FlyBuyCore.getInstance().orders.updatePickupMethod(orderID, builder.build()) { order, sdkError ->
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

        FlyBuyCore.getInstance().orders.rateOrder(
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

    // ── Customer ─────────────────────────────────────────────────────────────

    @PluginMethod
    fun getCurrentCustomer(call: PluginCall) {
        val ret = JSObject()
        val customer = FlyBuyCore.getInstance().customer.current
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

        FlyBuyCore.getInstance().customer.create(
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
    fun createCustomerWithLogin(call: PluginCall) {
        val infoObj = call.getObject("customerInfo")
            ?: return call.reject("customerInfo is required", "INVALID_ARGUMENT")
        val email = call.getString("email")
            ?: return call.reject("email is required", "INVALID_ARGUMENT")
        val password = call.getString("password")
            ?: return call.reject("password is required", "INVALID_ARGUMENT")
        val termsOfService = call.getBoolean("termsOfService") ?: false
        val ageVerification = call.getBoolean("ageVerification") ?: false

        FlyBuyCore.getInstance().customer.create(
            buildCustomerInfo(infoObj),
            email = email,
            password = password,
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
    fun loginWithToken(call: PluginCall) {
        val token = call.getString("token")
            ?: return call.reject("token is required", "INVALID_ARGUMENT")

        FlyBuyCore.getInstance().customer.loginWithToken(token) { customer, sdkError ->
            if (sdkError != null) return@loginWithToken rejectWithError(call, sdkError)
            if (customer == null) return@loginWithToken call.reject("No customer returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("customer", serializeCustomer(customer))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun logoutCustomer(call: PluginCall) {
        FlyBuyCore.getInstance().customer.logout()
        call.resolve()
    }

    @PluginMethod
    fun updateCustomer(call: PluginCall) {
        val infoObj = call.getObject("customerInfo")
            ?: return call.reject("customerInfo is required", "INVALID_ARGUMENT")

        FlyBuyCore.getInstance().customer.update(buildCustomerInfo(infoObj)) { customer, sdkError ->
            if (sdkError != null) return@update rejectWithError(call, sdkError)
            if (customer == null) return@update call.reject("No customer returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("customer", serializeCustomer(customer))
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun signUpCustomer(call: PluginCall) {
        val email = call.getString("email")
            ?: return call.reject("email is required", "INVALID_ARGUMENT")
        val password = call.getString("password")
            ?: return call.reject("password is required", "INVALID_ARGUMENT")

        FlyBuyCore.getInstance().customer.signUp(email, password) { customer, sdkError ->
            if (sdkError != null) return@signUp rejectWithError(call, sdkError)
            if (customer == null) return@signUp call.reject("No customer returned", "NOT_FOUND")
            val ret = JSObject()
            ret.put("customer", serializeCustomer(customer))
            call.resolve(ret)
        }
    }

    // ── Sites ─────────────────────────────────────────────────────────────────

    @PluginMethod
    fun fetchAllSites(call: PluginCall) {
        FlyBuyCore.getInstance().sites.fetchAll { sites, sdkError ->
            if (sdkError != null) return@fetchAll rejectWithError(call, sdkError)
            val ret = JSObject()
            ret.put("sites", (sites ?: emptyList()).map { serializeSite(it) }.toJSArray())
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun fetchSitesByQuery(call: PluginCall) {
        val query = call.getString("query")
            ?: return call.reject("query is required", "INVALID_ARGUMENT")

        FlyBuyCore.getInstance().sites.fetch(query = query) { sites, _, sdkError ->
            if (sdkError != null) return@fetch rejectWithError(call, sdkError)
            val ret = JSObject()
            ret.put("sites", (sites ?: emptyList()).map { serializeSite(it) }.toJSArray())
            call.resolve(ret)
        }
    }

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

        FlyBuyCore.getInstance().sites.fetch(region = region) { sites, sdkError ->
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

        FlyBuyCore.getInstance().sites.fetchByPartnerIdentifier(partnerIdentifier) { site, sdkError ->
            if (sdkError != null) return@fetchByPartnerIdentifier rejectWithError(call, sdkError)
            if (site == null) return@fetchByPartnerIdentifier call.reject("Site not found", "NOT_FOUND")
            val ret = JSObject()
            ret.put("site", serializeSite(site))
            call.resolve(ret)
        }
    }

    // ── Error Handling ────────────────────────────────────────────────────────

    private fun rejectWithError(call: PluginCall, sdkError: SdkError) {
        when (sdkError) {
            is PickupError -> call.reject(
                sdkError.userError() ?: "Pickup error: ${sdkError.errorType}",
                "PICKUP_ERROR"
            )
            is GenericSdkError<*> -> call.reject(
                sdkError.userError() ?: "SDK error: ${sdkError.errorType}",
                "SDK_ERROR"
            )
            else -> {
                val data = JSObject()
                data.put("statusCode", sdkError.code)
                call.reject(sdkError.userError() ?: "Error code: ${sdkError.code}", "API_ERROR", null, data)
            }
        }
    }

    // ── Serializers ───────────────────────────────────────────────────────────

    private fun serializeOrder(order: Order): JSObject {
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
            order.customer.name?.let { put("customerName", it) }
            order.customer.carType?.let { put("customerCarType", it) }
            order.customer.carColor?.let { put("customerCarColor", it) }
            order.customer.licensePlate?.let { put("customerCarPlate", it) }
            order.etaAt?.let { put("etaAtStop", it.toString()) }
            order.pickupWindow?.let { window ->
                val windowObj = JSObject()
                windowObj.put("start", window.start.toString())
                window.end?.let { windowObj.put("end", it.toString()) }
                put("pickupWindow", windowObj)
            }
        }
    }

    private fun serializeCustomer(customer: Customer): JSObject {
        return JSObject().apply {
            put("token", customer.apiToken)
            customer.email?.let { put("emailAddress", it) }
            put("name", customer.name)
            customer.carType?.let { put("carType", it) }
            customer.carColor?.let { put("carColor", it) }
            customer.licensePlate?.let { put("licensePlate", it) }
            customer.phone?.let { put("phone", it) }
        }
    }

    private fun serializeSite(site: Site): JSObject {
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

    // ── Builders ──────────────────────────────────────────────────────────────

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

        if (obj.has("disableOrderFire")) {
            builder.setDisableOrderFire(obj.getBool("disableOrderFire") ?: false)
        }
        if (obj.has("disablePromiseTimeScheduling")) {
            builder.setDisablePromiseTimeScheduling(obj.getBool("disablePromiseTimeScheduling") ?: false)
        }
        if (obj.has("orderFireMakeIntervalSeconds")) {
            builder.setOrderFireMakeIntervalSeconds(obj.getInteger("orderFireMakeIntervalSeconds") ?: 0)
        }

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

    private fun buildCustomerInfo(obj: JSObject): CustomerInfo {
        return CustomerInfo(
            name = obj.getString("name") ?: "",
            carType = obj.getString("carType") ?: "",
            carColor = obj.getString("carColor") ?: "",
            licensePlate = obj.getString("licensePlate") ?: "",
            phone = obj.getString("phone") ?: ""
        )
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun List<JSObject>.toJSArray(): JSArray {
        val arr = JSArray()
        forEach { arr.put(it) }
        return arr
    }
}