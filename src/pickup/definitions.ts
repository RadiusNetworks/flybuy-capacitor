import type { PluginListenerHandle } from '@capacitor/core';
import type {
  FlyBuyOrder,
  OrderOptions,
  CustomerState,
  OrderState,
  PickupType,
} from '../definitions';

export interface FlybuyPickupPlugin {

  // ── Orders ──────────────────────────────────

  /** Fetch orders from the server and update local cache */
  fetchOrders(): Promise<{ orders: FlyBuyOrder[] }>;

  /** Return cached orders — no network call */
  getOrders(options?: {
    filter?: 'all' | 'open' | 'closed';
  }): Promise<{ orders: FlyBuyOrder[] }>;

  /** Fetch a single unclaimed order by redemption code */
  fetchOrderByRedemptionCode(options: {
    redemptionCode: string;
  }): Promise<{ order: FlyBuyOrder }>;

  /** Create an order using a known Flybuy site ID */
  createOrderBySiteID(options: {
    siteID: number;
    orderOptions: OrderOptions;
  }): Promise<{ order: FlyBuyOrder }>;

  /** Create an order using a site partner identifier (only if site is "live") */
  createOrderBySitePartnerIdentifier(options: {
    sitePartnerIdentifier: string;
    orderOptions: OrderOptions;
  }): Promise<{ order: FlyBuyOrder }>;

  /** Claim an order and start location tracking */
  claimOrder(options: {
    redemptionCode: string;
    orderOptions: OrderOptions;
  }): Promise<{ order: FlyBuyOrder }>;

  /** Update the merchant-facing order state */
  updateOrderState(options: {
    orderID: number;
    state: OrderState | string;
  }): Promise<{ order: FlyBuyOrder }>;

  /**
   * Update the customer-facing order state.
   * spotIdentifier is only valid when customerState = 'waiting' (max 35 chars).
   */
  updateOrderCustomerState(options: {
    orderID: number;
    customerState: CustomerState | string;
    spotIdentifier?: string;
  }): Promise<{ order: FlyBuyOrder }>;

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
  rateOrder(options: {
    orderID: number;
    rating: number;
    comments?: string;
    categories?: string[];
  }): Promise<{ order: FlyBuyOrder }>;

  // ── Events ───────────────────────────────────

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