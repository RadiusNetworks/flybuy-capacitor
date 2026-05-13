#import <Capacitor/Capacitor.h>

CAP_PLUGIN(FlybuyNotifyPlugin, "FlybuyNotify",
    CAP_PLUGIN_METHOD(updateCustomTemplateContent, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(sync, CAPPluginReturnPromise);
)