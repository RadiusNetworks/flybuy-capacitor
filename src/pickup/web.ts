import { WebPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';
import type { FlybuyPickupPlugin } from './definitions';

export class FlybuyPickupWeb extends WebPlugin implements FlybuyPickupPlugin {

  private notSupported(method: string): never {
    throw this.unimplemented(`${method} is not supported on web.`);
  }

  // ── Events ────────────────────────────────────

  async addListener(
    _eventName: 'ordersUpdated' | 'orderUpdated' | 'ordersError',
    _listenerFunc: (data: any) => void
  ): Promise<PluginListenerHandle> {
    return this.notSupported('addListener');
  }
}