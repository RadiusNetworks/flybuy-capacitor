import { registerPlugin } from '@capacitor/core';
import type { FlybuyNotifyPlugin } from './definitions';

const FlybuyNotify = registerPlugin<FlybuyNotifyPlugin>('FlybuyNotify', {
  web: () => import('./web').then((m) => new m.FlybuyNotifyWeb()),
});

export * from './definitions';
export { FlybuyNotify };
