#import <Capacitor/Capacitor.h>

CAP_PLUGIN(FlybuyPlugin, "Flybuy",
    // Orders
    CAP_PLUGIN_METHOD(fetchOrders, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getOrders, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(fetchOrderByRedemptionCode, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(createOrderBySiteID, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(createOrderBySitePartnerIdentifier, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(claimOrder, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(updateOrderState, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(updateOrderCustomerState, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(updatePickupMethod, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(rateOrder, CAPPluginReturnPromise);

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
)
