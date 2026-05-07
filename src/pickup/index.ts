import { registerPlugin } from '@capacitor/core';
import type { FlybuyPickupPlugin } from './definitions';

const FlybuyPickup = registerPlugin<FlybuyPickupPlugin>('FlybuyPickup', {
  web: () => import('./web').then((m) => new m.FlybuyPickupWeb()),
});

export * from './definitions';
export { FlybuyPickup };
