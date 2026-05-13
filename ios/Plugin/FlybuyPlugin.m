#import <Capacitor/Capacitor.h>

CAP_PLUGIN(FlybuyPlugin, "Flybuy",
    // Customer
    CAP_PLUGIN_METHOD(getCurrentCustomer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(createCustomer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(login, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(loginWithToken, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(logout, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(updateCustomer, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(signUp, CAPPluginReturnPromise);

    // Sites
    CAP_PLUGIN_METHOD(fetchSitesByRegion, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(fetchSiteByPartnerIdentifier, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(fetchSitesNearPlace, CAPPluginReturnPromise);

    // Places
    CAP_PLUGIN_METHOD(placesSuggest, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(placesRetrieve, CAPPluginReturnPromise);

    // Deep Links
    CAP_PLUGIN_METHOD(parseLink, CAPPluginReturnPromise);
)