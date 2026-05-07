package com.radiusnetworks.flybuy.capacitor

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
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
}
