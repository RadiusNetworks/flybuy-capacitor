package com.radiusnetworks.flybuy.capacitor

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.radiusnetworks.flybuy.sdk.data.common.SdkError
import com.radiusnetworks.flybuy.sdk.data.location.CircularRegion
import com.radiusnetworks.flybuy.sdk.notify.NotificationInfo
import com.radiusnetworks.flybuy.sdk.notify.NotifyManager

@CapacitorPlugin(name = "FlybuyNotify")
class FlybuyNotifyPlugin : Plugin() {

    @PluginMethod
    fun updateCustomTemplateContent(call: PluginCall) {
        val contentObj = call.getObject("content")
            ?: return call.reject("content is required", "INVALID_ARGUMENT")

        val templateContent = mutableMapOf<String, String>()
        contentObj.keys().forEach { key ->
            contentObj.getString(key)?.let { value ->
                templateContent[key] = value
            }
        }

        NotifyManager.getInstance().updateCustomTemplateContent(templateContent)
        call.resolve()
    }

    @PluginMethod
    fun sync(call: PluginCall) {
        val force = call.getBoolean("force") ?: false
        NotifyManager.getInstance().sync(force) { sdkError ->
            if (sdkError != null) return@sync rejectWithError(call, sdkError)
            call.resolve()
        }
    }

    private fun serializeSite(site: com.radiusnetworks.flybuy.sdk.data.room.domain.Site): JSObject {
        return JSObject().apply {
            put("id", site.id)
            site.name?.let { put("name", it) }
            site.partnerIdentifier?.let { put("partnerIdentifier", it) }
            site.fullAddress?.let { put("fullAddress", it) }
            site.latitude?.let { put("latitude", it) }
            site.longitude?.let { put("longitude", it) }
        }
    }

    private fun rejectWithError(call: PluginCall, sdkError: SdkError) {
        val data = JSObject()
        data.put("statusCode", sdkError.code)
        call.reject(sdkError.userError(), "API_ERROR", null, data)
    }

    private fun List<JSObject>.toJSArray(): com.getcapacitor.JSArray {
        val arr = com.getcapacitor.JSArray()
        forEach { arr.put(it) }
        return arr
    }
}