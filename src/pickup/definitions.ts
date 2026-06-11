import type { PluginListenerHandle } from '@capacitor/core';
import type { FlyBuyOrder } from '../definitions';

// ─────────────────────────────────────────────
// Public Instance API
// ─────────────────────────────────────────────

export interface PickupInstance {
  addListener(
    eventName: 'ordersUpdated',
    listenerFunc: (data: { orders: FlyBuyOrder[] }) => void
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'orderUpdated',
    listenerFunc: (data: { order: FlyBuyOrder }) => void
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'ordersError',
    listenerFunc: (data: { error: string }) => void
  ): Promise<PluginListenerHandle>;
}

// ─────────────────────────────────────────────
// Internal Native Bridge Interface
// ─────────────────────────────────────────────

/** @internal — not part of the public API. Use getPickupInstance() instead. */
export interface FlybuyPickupPlugin {
  addListener(
    eventName: 'ordersUpdated',
    listenerFunc: (data: { orders: FlyBuyOrder[] }) => void
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'orderUpdated',
    listenerFunc: (data: { order: FlyBuyOrder }) => void
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'ordersError',
    listenerFunc: (data: { error: string }) => void
  ): Promise<PluginListenerHandle>;
}