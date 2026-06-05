package com.radiusnetworks.flybuy.capacitor

import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.radiusnetworks.flybuy.sdk.FlyBuyCore
import com.radiusnetworks.flybuy.sdk.data.common.SdkError
import com.radiusnetworks.flybuy.sdk.data.room.domain.Order
import com.radiusnetworks.flybuy.sdk.data.room.domain.PickupWindow
import com.radiusnetworks.flybuy.sdk.data.room.domain.open
import com.radiusnetworks.flybuy.sdk.manager.builder.OrderOptions
import com.radiusnetworks.flybuy.sdk.manager.builder.PickupMethodOptions
import java.time.Instant

@CapacitorPlugin(name = "FlybuyPickup")
class FlybuyPickupPlugin : Plugin() {

    // ── Instance Helper ───────────────────────────────────────────────────────

    private fun getInstance(call: PluginCall) =
        FlyBuyCore.getInstance(call.getString("appAuthId"))

    // ── Orders ───────────────────────────────────────────────────────────────

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

    private fun rejectWithError(call: PluginCall, sdkError: SdkError) {
        FlybuyPlugin().rejectWithError(call, sdkError)
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