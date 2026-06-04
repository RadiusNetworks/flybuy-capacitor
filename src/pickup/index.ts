import { registerPlugin } from '@capacitor/core';
import type { FlybuyPickupPlugin, PickupInstance } from './definitions';

export * from './definitions';

// Re-export shared types so consumers can import from 'flybuy-capacitor/pickup'
export type { FlyBuyOrder, OrderOptions, OrderState, CustomerState, PickupType } from '../definitions';

const FlybuyPickupNative = registerPlugin<FlybuyPickupPlugin>('FlybuyPickup', {
  web: () => import('./web').then((m) => new m.FlybuyPickupWeb()),
});

/**
 * Returns a scoped accessor for a FlyBuy Pickup instance.
 * Pass null (or omit) for the primary instance, or an appAuthId string for a secondary project.
 *
 * Usage:
 *   const pickup = getPickupInstance();          // primary instance
 *   const pickup = getPickupInstance('139');     // secondary project
 *
 *   const { order } = await pickup.orders.fetchByRedemptionCode({ redemptionCode: 'ABC123' });
 *   await pickup.orders.claim({ redemptionCode: 'ABC123', orderOptions: { customerName: 'Marty McFly' } });
 *   await pickup.orders.updateCustomerState({ orderID: order.id, customerState: CustomerState.EnRoute });
 */
export function getPickupInstance(appAuthId: string | null = null): PickupInstance {
  return {
    orders: {
      fetch: () =>
        FlybuyPickupNative.fetchOrders({ appAuthId }),
      get: (options) =>
        FlybuyPickupNative.getOrders({ ...options, appAuthId }),
      fetchByRedemptionCode: ({ redemptionCode }) =>
        FlybuyPickupNative.fetchOrderByRedemptionCode({ redemptionCode, appAuthId }),
      createWithSiteId: ({ siteID, orderOptions }) =>
        FlybuyPickupNative.createOrderBySiteID({ siteID, orderOptions, appAuthId }),
      createWithSitePartnerIdentifier: ({ sitePartnerIdentifier, orderOptions }) =>
        FlybuyPickupNative.createOrderBySitePartnerIdentifier({ sitePartnerIdentifier, orderOptions, appAuthId }),
      claim: ({ redemptionCode, orderOptions }) =>
        FlybuyPickupNative.claimOrder({ redemptionCode, orderOptions, appAuthId }),
      updateState: ({ orderID, state }) =>
        FlybuyPickupNative.updateOrderState({ orderID, state, appAuthId }),
      updateCustomerState: ({ orderID, customerState, spotIdentifier }) =>
        FlybuyPickupNative.updateOrderCustomerState({ orderID, customerState, spotIdentifier, appAuthId }),
      updatePickupMethod: ({ orderID, ...options }) =>
        FlybuyPickupNative.updatePickupMethod({ orderID, ...options, appAuthId }),
      rateOrder: ({ orderID, rating, comments, categories }) =>
        FlybuyPickupNative.rateOrder({ orderID, rating, comments, categories, appAuthId }),
    },
    addListener: (eventName, listenerFunc) =>
      FlybuyPickupNative.addListener(eventName as any, listenerFunc as any),
  };
}