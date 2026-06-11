package com.radiusnetworks.flybuy.capacitor

import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.annotation.CapacitorPlugin
import com.radiusnetworks.flybuy.sdk.FlyBuyCore
import com.radiusnetworks.flybuy.sdk.data.room.domain.Order

@CapacitorPlugin(name = "FlybuyPickup")
class FlybuyPickupPlugin : Plugin() {

    // ── Order Observers ───────────────────────────────────────────────────────

    override fun load() {
        val orders = FlyBuyCore.getInstance(null).orders

        orders.openLiveData.observeForever { openOrders: List<Order>? ->
            openOrders ?: return@observeForever
            val ordersArray = JSArray()
            openOrders.forEach { ordersArray.put(flybuyPlugin().serializeOrder(it)) }
            notifyListeners("ordersUpdated", JSObject().apply {
                put("orders", ordersArray)
            })
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun flybuyPlugin(): FlybuyPlugin =
        bridge.getPlugin("Flybuy").instance as FlybuyPlugin
}