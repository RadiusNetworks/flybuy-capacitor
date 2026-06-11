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
  DriveThru = 'drive_thru',
}

// ─────────────────────────────────────────────
// Link Types
// ─────────────────────────────────────────────

export enum LinkType {
  DineIn = 'dineIn',
  Redemption = 'redemption',
  Other = 'other',
}

export interface LinkDetails {
  url: string;
  type: LinkType;
  params?: Record<string, string>;
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
  name: string;
  carType?: string;
  carColor?: string;
  licensePlate?: string;
  phone?: string;
}

export interface FlyBuyCustomer {
  token: string;
  emailAddress?: string;
  name?: string;
  carType?: string;
  carColor?: string;
  licensePlate?: string;
  phone?: string;
}

export interface PickupWindow {
  start: string;   // ISO8601
  end?: string;    // ISO8601 — nil means ASAP
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

  partnerIdentifier?: string;
  partnerIdentifierForCrew?: string;
  partnerIdentifierForCustomer?: string;

  redeemedAt?: string;
  isOpen: boolean;

  customerRatingValue?: number;

  spotIdentifierEntryEnabled?: boolean;
  spotIdentifierInputType?: string;

  pickupType?: PickupType | string;
  pickupWindow?: PickupWindow;
  etaAtStop?: string;

  customerName?: string;
  customerCarType?: string;
  customerCarColor?: string;
  customerCarPlate?: string;
  customerPhone?: string;

  siteID: number;
}

export interface OrderOptions {
  customerName: string;
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
  handoffVehicleLocation?: string;
  pickupWindow?: PickupWindow;
  loyaltyIdentifier?: string;
  loyaltyProvider?: string;
  disableOrderFire?: boolean;
  disablePromiseTimeScheduling?: boolean;
  orderFireMakeIntervalSeconds?: number;
}

// ─────────────────────────────────────────────
// Places
// ─────────────────────────────────────────────

export interface CircularRegion {
  latitude: number;
  longitude: number;
  radius: number;   // meters
}

export interface FlyBuyPlace {
  name: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  placeID?: string;
}

export interface PlaceSuggestOptions {
  latitude?: number;
  longitude?: number;
}

// ─────────────────────────────────────────────
// Public Instance API
// ─────────────────────────────────────────────

export interface ICustomerMethods {
  getCurrent(): Promise<{ customer: FlyBuyCustomer | null }>;
  create(options: { customerInfo: CustomerInfo; termsOfService: boolean; ageVerification: boolean }): Promise<{ customer: FlyBuyCustomer }>;
  login(options: { email: string; password: string }): Promise<{ customer: FlyBuyCustomer }>;
  loginWithToken(options: { token: string }): Promise<{ customer: FlyBuyCustomer }>;
  logout(): Promise<void>;
  update(options: { customerInfo: CustomerInfo }): Promise<{ customer: FlyBuyCustomer }>;
  signUp(options: { email: string; password: string }): Promise<{ customer: FlyBuyCustomer }>;
}

export interface ISiteMethods {
  fetchByRegion(options: { latitude: number; longitude: number; radiusMeters: number }): Promise<{ sites: FlyBuySite[] }>;
  fetchByPartnerIdentifier(options: { partnerIdentifier: string }): Promise<{ site: FlyBuySite }>;
  fetchNearPlace(options: { place: FlyBuyPlace; radius: number }): Promise<{ sites: FlyBuySite[] }>;
}

export interface IPlaceMethods {
  suggest(options: { query: string; options?: PlaceSuggestOptions }): Promise<{ places: FlyBuyPlace[] }>;
  retrieve(options: { place: FlyBuyPlace }): Promise<{ place: FlyBuyPlace }>;
}

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

export interface Instance {
  customer: ICustomerMethods;
  sites: ISiteMethods;
  places: IPlaceMethods;
  orders: IOrderMethods;
  parseLink(options: { url: string }): Promise<LinkDetails>;
  addListener(
    eventName: 'ordersUpdated',
    listenerFunc: (data: { orders: FlyBuyOrder[] }) => void
  ): Promise<import('@capacitor/core').PluginListenerHandle>;
  addListener(
    eventName: 'orderUpdated',
    listenerFunc: (data: { order: FlyBuyOrder }) => void
  ): Promise<import('@capacitor/core').PluginListenerHandle>;
  addListener(
    eventName: 'ordersError',
    listenerFunc: (data: { error: string }) => void
  ): Promise<import('@capacitor/core').PluginListenerHandle>;
}

// ─────────────────────────────────────────────
// Internal Native Bridge Interface
// ─────────────────────────────────────────────

/** @internal — not part of the public API. Use getInstance() instead. */
export interface FlybuyPlugin {
  getCurrentCustomer(options: { appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer | null }>;
  createCustomer(options: { customerInfo: CustomerInfo; termsOfService: boolean; ageVerification: boolean; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }>;
  login(options: { email: string; password: string; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }>;
  loginWithToken(options: { token: string; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }>;
  logout(options: { appAuthId: string | null }): Promise<void>;
  updateCustomer(options: { customerInfo: CustomerInfo; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }>;
  signUp(options: { email: string; password: string; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }>;
  fetchSitesByRegion(options: { latitude: number; longitude: number; radiusMeters: number; appAuthId: string | null }): Promise<{ sites: FlyBuySite[] }>;
  fetchSiteByPartnerIdentifier(options: { partnerIdentifier: string; appAuthId: string | null }): Promise<{ site: FlyBuySite }>;
  fetchSitesNearPlace(options: { place: FlyBuyPlace; radius: number; appAuthId: string | null }): Promise<{ sites: FlyBuySite[] }>;
  placesSuggest(options: { query: string; options?: PlaceSuggestOptions; appAuthId: string | null }): Promise<{ places: FlyBuyPlace[] }>;
  placesRetrieve(options: { place: FlyBuyPlace; appAuthId: string | null }): Promise<{ place: FlyBuyPlace }>;
  parseLink(options: { url: string }): Promise<LinkDetails>;
  // Orders
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
  ): Promise<import('@capacitor/core').PluginListenerHandle>;
  addListener(
    eventName: 'orderUpdated',
    listenerFunc: (data: { order: FlyBuyOrder }) => void
  ): Promise<import('@capacitor/core').PluginListenerHandle>;
  addListener(
    eventName: 'ordersError',
    listenerFunc: (data: { error: string }) => void
  ): Promise<import('@capacitor/core').PluginListenerHandle>;
}