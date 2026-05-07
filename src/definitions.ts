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
  // Note: 'delivery' is reserved for delivery service providers (DSPs)
  // and should not be used in customer-facing apps.
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
  params?: Record<string, string>;  // e.g. { r: 'REDEMPTION_CODE' } for redemption links
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
  partnerIdentifierForCustomer?: string;

  // Status flags
  redeemedAt?: string;                    // ISO8601 — empty means unclaimed
  isOpen: boolean;

  // Rating
  customerRatingValue?: number;           // if set, order already rated

  // Spot
  spotIdentifierEntryEnabled?: boolean;
  spotIdentifierInputType?: string;

  // Pickup details
  pickupType?: PickupType | string;
  pickupWindow?: PickupWindow;
  etaAtStop?: string;                     // ISO8601

  // Customer vehicle info
  customerName?: string;
  customerCarType?: string;
  customerCarColor?: string;
  customerCarPlate?: string;
  customerPhone?: string;

  // Site
  siteID: number;
}

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
  handoffVehicleLocation?: string;
  pickupWindow?: PickupWindow;
  loyaltyIdentifier?: string;
  loyaltyProvider?: string;
  disableOrderFire?: boolean;
  disablePromiseTimeScheduling?: boolean;
  orderFireMakeIntervalSeconds?: number;
}

// ─────────────────────────────────────────────
// Core Plugin Interface (customer + sites + links)
// ─────────────────────────────────────────────

export interface FlybuyPlugin {

  // ── Customer ─────────────────────────────────

  getCurrentCustomer(): Promise<{ customer: FlyBuyCustomer | null }>;

  createCustomer(options: {
    customerInfo: CustomerInfo;
    termsOfService: boolean;
    ageVerification: boolean;
  }): Promise<{ customer: FlyBuyCustomer }>;

  createCustomerWithLogin(options: {
    customerInfo: CustomerInfo;
    email: string;
    password: string;
    termsOfService: boolean;
    ageVerification: boolean;
  }): Promise<{ customer: FlyBuyCustomer }>;

  loginWithToken(options: {
    token: string;
  }): Promise<{ customer: FlyBuyCustomer }>;

  logoutCustomer(): Promise<void>;

  updateCustomer(options: {
    customerInfo: CustomerInfo;
  }): Promise<{ customer: FlyBuyCustomer }>;

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

  // ── Deep Links ────────────────────────────────

  parseLink(options: { url: string }): Promise<LinkDetails>;
}