import type { PluginListenerHandle } from '@capacitor/core';
import type {
  FlyBuyOrder,
  OrderOptions,
  CustomerState,
  OrderState,
  PickupType,
} from '../definitions';

// ─────────────────────────────────────────────
// Public Instance API
// ─────────────────────────────────────────────

export interface IOrderMethods {
  /** Fetch orders from the server and update local cache */
  fetch(): Promise<{ orders: FlyBuyOrder[] }>;

  /** Return cached orders — no network call */
  get(options?: { filter?: 'all' | 'open' | 'closed' }): Promise<{ orders: FlyBuyOrder[] }>;

  /** Fetch a single unclaimed order by redemption code */
  fetchByRedemptionCode(options: { redemptionCode: string }): Promise<{ order: FlyBuyOrder }>;

  /** Create an order using a known Flybuy site ID */
  createWithSiteId(options: { siteID: number; orderOptions: OrderOptions }): Promise<{ order: FlyBuyOrder }>;

  /** Create an order using a site partner identifier */
  createWithSitePartnerIdentifier(options: { sitePartnerIdentifier: string; orderOptions: OrderOptions }): Promise<{ order: FlyBuyOrder }>;

  /** Claim an order and start location tracking */
  claim(options: { redemptionCode: string; orderOptions: OrderOptions }): Promise<{ order: FlyBuyOrder }>;

  /** Update the merchant-facing order state */
  updateState(options: { orderID: number; state: OrderState | string }): Promise<{ order: FlyBuyOrder }>;

  /**
   * Update the customer-facing order state.
   * spotIdentifier is only valid when customerState = 'waiting' (max 35 chars).
   */
  updateCustomerState(options: { orderID: number; customerState: CustomerState | string; spotIdentifier?: string }): Promise<{ order: FlyBuyOrder }>;

  /** Update pickup method and vehicle info while order is open */
  updatePickupMethod(options: {
    orderID: number;
    pickupType: PickupType | string;
    customerCarType?: string;
    customerCarColor?: string;
    customerLicensePlate?: string;
    handoffVehicleLocation?: string;
  }): Promise<{ order: FlyBuyOrder }>;

  /** Rate a completed order */
  rateOrder(options: { orderID: number; rating: number; comments?: string; categories?: string[] }): Promise<{ order: FlyBuyOrder }>;
}

export interface PickupInstance {
  orders: IOrderMethods;

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
  fetchOrders(options: { appAuthId: string | null }): Promise<{ orders: FlyBuyOrder[] }>;
  getOrders(options: { filter?: 'all' | 'open' | 'closed'; appAuthId: string | null }): Promise<{ orders: FlyBuyOrder[] }>;
  fetchOrderByRedemptionCode(options: { redemptionCode: string; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }>;
  createOrderBySiteID(options: { siteID: number; orderOptions: OrderOptions; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }>;
  createOrderBySitePartnerIdentifier(options: { sitePartnerIdentifier: string; orderOptions: OrderOptions; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }>;
  claimOrder(options: { redemptionCode: string; orderOptions: OrderOptions; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }>;
  updateOrderState(options: { orderID: number; state: OrderState | string; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }>;
  updateOrderCustomerState(options: { orderID: number; customerState: CustomerState | string; spotIdentifier?: string; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }>;
  updatePickupMethod(options: { orderID: number; pickupType: PickupType | string; customerCarType?: string; customerCarColor?: string; customerLicensePlate?: string; handoffVehicleLocation?: string; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }>;
  rateOrder(options: { orderID: number; rating: number; comments?: string; categories?: string[]; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }>;

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