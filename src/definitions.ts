import type { PluginListenerHandle } from '@capacitor/core';

// ─────────────────────────────────────────────
// Customer State Values
// ─────────────────────────────────────────────

export enum CustomerState {
  Created = 'created',
  EnRoute = 'en_route',
  Nearby = 'nearby',
  Arrived = 'arrived',
  Waiting = 'waiting',
  Departed = 'departed',
  Completed = 'completed',
}

// ─────────────────────────────────────────────
// Order State Values
// ─────────────────────────────────────────────

export enum OrderState {
  Created = 'created',
  Preparing = 'preparing',
  Ready = 'ready',
  Delayed = 'delayed',
  DeliveryDispatched = 'delivery_dispatched',
  DriverAssigned = 'driver_assigned',
  DeliveryFailed = 'delivery_failed',
  PickedUp = 'picked_up',
  OutForDelivery = 'out_for_delivery',
  Undeliverable = 'undeliverable',
  Cancelled = 'cancelled',
  Completed = 'completed',
  Expired = 'expired',
}

// ─────────────────────────────────────────────
// Pickup Type
// ─────────────────────────────────────────────

export enum PickupType {
  Curbside = 'curbside',
  Pickup = 'pickup',
  Delivery = 'delivery',
}

// ─────────────────────────────────────────────
// Error Codes
// ─────────────────────────────────────────────

export enum FlybuyErrorCode {
  InvalidArgument = 'INVALID_ARGUMENT',
  NotFound = 'NOT_FOUND',
  OrdersError = 'ORDERS_ERROR',
  ApiError = 'API_ERROR',
  FlybuyError = 'FLYBUY_ERROR',
  UnknownError = 'UNKNOWN_ERROR',
}

// ─────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────

export interface CustomerInfo {
  name: string;             // required
  carType?: string;
  carColor?: string;
  licensePlate?: string;
  phone?: string;           // pass empty string if not used
}

export interface FlyBuyCustomer {
  token: string;            // store securely for subsequent loginWithToken calls
  emailAddress?: string;
  name?: string;
  carType?: string;
  carColor?: string;
  licensePlate?: string;
  phone?: string;
}

export interface PickupWindow {
  start: string;            // ISO8601 — same as end if single time
  end?: string;             // ISO8601 — nil means ASAP
}

export interface PickupConfig {
  pickupTypes?: string[];
  defaultPickupType?: string;
  partnerIdentifier?: string;
}

export interface FlyBuySite {
  id: number;
  name?: string;
  partnerIdentifier?: string;
  streetAddress?: string;
  fullAddress?: string;
  locality?: string;
  region?: string;
  country?: string;
  postalCode?: string;
  latitude?: number;
  longitude?: number;
  instructions?: string;
  descriptionText?: string;
  coverPhotoURL?: string;
  pickupConfig?: PickupConfig;
}

export interface FlyBuyOrder {
  id: number;
  state: OrderState | string;
  customerState: CustomerState | string;

  // Identifiers
  partnerIdentifier?: string;
  partnerIdentifierForCrew?: string;
  partnerIdentifierForCustomer?: string;  // display to customer; fall back to partnerIdentifier if null

  // Status flags
  redeemedAt?: string;                    // ISO8601 — empty means unclaimed
  isOpen: boolean;                        // false means completed

  // Rating
  customerRatingValue?: number;           // if set, order already rated — hide rating UI

  // Spot
  spotIdentifierEntryEnabled?: boolean;
  spotIdentifierInputType?: string;

  // Pickup details
  pickupType?: PickupType | string;
  pickupWindow?: PickupWindow;
  etaAtStop?: string;                     // ISO8601

  // Customer vehicle info (for this order — may differ from logged-in customer)
  customerName?: string;
  customerCarType?: string;
  customerCarColor?: string;
  customerCarPlate?: string;
  customerPhone?: string;

  // Site
  siteID: number;
}

// ─────────────────────────────────────────────
// Input Types
// ─────────────────────────────────────────────

export interface OrderOptions {
  customerName: string;                   // required
  customerPhone?: string;
  customerCarColor?: string;
  customerCarType?: string;
  customerCarPlate?: string;
  partnerIdentifier?: string;
  partnerIdentifierForCrew?: string;
  partnerIdentifierForCustomer?: string;
  pickupType?: PickupType | string;
  state?: OrderState | string;
  transportMode?: 'driving' | 'walking' | 'biking' | string;
  handoffVehicleLocation?: string;        // e.g. "driver_front", "passenger_rear", "trunk_rear"
  pickupWindow?: PickupWindow;
  loyaltyIdentifier?: string;
  loyaltyProvider?: string;
  disableOrderFire?: boolean;
  disablePromiseTimeScheduling?: boolean;
  orderFireMakeIntervalSeconds?: number;
}

// ─────────────────────────────────────────────
// Plugin Interface
// ─────────────────────────────────────────────

export interface FlybuyPlugin {

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
    rating: number;                       // 1–5
    comments?: string;
    categories?: string[];
  }): Promise<{ order: FlyBuyOrder }>;

  // ── Customer ─────────────────────────────────

  /** Returns the currently logged-in customer, or null */
  getCurrentCustomer(): Promise<{ customer: FlyBuyCustomer | null }>;

  /** Create an anonymous customer (no email/password) */
  createCustomer(options: {
    customerInfo: CustomerInfo;
    termsOfService: boolean;              // must be true
    ageVerification: boolean;             // must be true
  }): Promise<{ customer: FlyBuyCustomer }>;

  /** Create a customer with email and password credentials */
  createCustomerWithLogin(options: {
    customerInfo: CustomerInfo;
    email: string;
    password: string;
    termsOfService: boolean;
    ageVerification: boolean;
  }): Promise<{ customer: FlyBuyCustomer }>;

  /** Log in using a previously stored customer token */
  loginWithToken(options: {
    token: string;
  }): Promise<{ customer: FlyBuyCustomer }>;

  /** Clear current customer and order data */
  logoutCustomer(): Promise<void>;

  /** Update the logged-in customer's info */
  updateCustomer(options: {
    customerInfo: CustomerInfo;
  }): Promise<{ customer: FlyBuyCustomer }>;

  /**
   * Link email and password to the current anonymous customer.
   * Call after createCustomer() if the user later wants a persistent account.
   */
  signUpCustomer(options: {
    email: string;
    password: string;
  }): Promise<{ customer: FlyBuyCustomer }>;

  // ── Sites ────────────────────────────────────

  fetchAllSites(): Promise<{ sites: FlyBuySite[] }>;

  fetchSitesByQuery(options: {
    query: string;
  }): Promise<{ sites: FlyBuySite[] }>;

  fetchSitesByRegion(options: {
    latitude: number;
    longitude: number;
    radiusMeters: number;
  }): Promise<{ sites: FlyBuySite[] }>;

  fetchSiteByPartnerIdentifier(options: {
    partnerIdentifier: string;
  }): Promise<{ site: FlyBuySite }>;

  // ── Events ───────────────────────────────────

  /** Fired when the full order list is updated */
  addListener(
    eventName: 'ordersUpdated',
    listenerFunc: (data: { orders: FlyBuyOrder[] }) => void
  ): Promise<PluginListenerHandle>;

  /** Fired when a single order is updated */
  addListener(
    eventName: 'orderUpdated',
    listenerFunc: (data: { order: FlyBuyOrder }) => void
  ): Promise<PluginListenerHandle>;

  /** Fired when an order fetch error occurs */
  addListener(
    eventName: 'ordersError',
    listenerFunc: (data: { error: string }) => void
  ): Promise<PluginListenerHandle>;
}
