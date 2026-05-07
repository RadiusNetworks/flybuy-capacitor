import { registerPlugin } from '@capacitor/core';
import type { FlybuyPickupPlugin } from './definitions';

const FlybuyPickup = registerPlugin<FlybuyPickupPlugin>('FlybuyPickup', {
  web: () => import('./web').then((m) => new m.FlybuyPickupWeb()),
});

export * from './definitions';
export { FlybuyPickup };

// Re-export shared types so consumers can import from 'flybuy-capacitor/pickup'
export type { FlyBuyOrder, OrderOptions, OrderState, CustomerState, PickupType } from '../definitions';