#import <Capacitor/Capacitor.h>

CAP_PLUGIN(FlybuyPlugin, "Flybuy",
    // Customer
    CAP_PLUGIN_METHOD(getCurrentCustomer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(createCustomer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(createCustomerWithLogin, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(loginWithToken, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(logoutCustomer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(updateCustomer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(signUpCustomer, CAPPluginReturnPromise);

    // Sites
    CAP_PLUGIN_METHOD(fetchAllSites, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(fetchSitesByQuery, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(fetchSitesByRegion, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(fetchSiteByPartnerIdentifier, CAPPluginReturnPromise);

    // Deep Links
    CAP_PLUGIN_METHOD(parseLink, CAPPluginReturnPromise);
)
