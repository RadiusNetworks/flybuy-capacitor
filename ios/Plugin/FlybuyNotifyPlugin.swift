import Capacitor
import FlyBuyNotify

@objc(FlybuyNotifyPlugin)
public class FlybuyNotifyPlugin: CAPPlugin {

    @objc func updateCustomTemplateContent(_ call: CAPPluginCall) {
        guard let content = call.getObject("content") else {
            return call.reject("content is required", "INVALID_ARGUMENT")
        }
        var templateContent: [String: String] = [:]
        for key in content.keys {
            if let value = content[key] as? String {
                templateContent[key] = value
            }
        }
        FlyBuyNotify.Manager.shared.updateCustomTemplateContent(templateContent)
        call.resolve()
    }
}
