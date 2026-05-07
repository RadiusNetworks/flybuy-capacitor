#import <Capacitor/Capacitor.h>

CAP_PLUGIN(FlybuyPickupPlugin, "FlybuyPickup",
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
)
