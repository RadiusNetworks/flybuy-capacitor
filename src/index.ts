import { registerPlugin } from '@capacitor/core';
import type { FlybuyPlugin } from './definitions';

const Flybuy = registerPlugin<FlybuyPlugin>('Flybuy', {
  web: () => import('./web').then((m) => new m.FlybuyWeb()),
});

export * from './definitions';
export { Flybuy };