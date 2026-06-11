import { registerPlugin } from '@capacitor/core';
import type { FlybuyPickupPlugin, PickupInstance } from './definitions';

export * from './definitions';

const FlybuyPickupNative = registerPlugin<FlybuyPickupPlugin>('FlybuyPickup', {
  web: () => import('./web').then((m) => new m.FlybuyPickupWeb()),
});

/**
 * Returns a scoped accessor for a FlyBuy Pickup instance.
 * Pass null (or omit) for the primary instance, or an appAuthId string for a secondary project.
 *
 * Usage:
 *   const pickup = getPickupInstance();      // primary instance
 *   const pickup = getPickupInstance('139'); // secondary project
 *
 *   pickup.addListener('ordersUpdated', ({ orders }) => { ... });
 *   pickup.addListener('orderUpdated', ({ order }) => { ... });
 */
export function getPickupInstance(_appAuthId: string | null = null): PickupInstance {
  return {
    addListener: (eventName, listenerFunc) =>
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      FlybuyPickupNative.addListener(eventName as any, listenerFunc as any),
  };
}