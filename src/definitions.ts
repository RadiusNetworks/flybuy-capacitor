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

export interface Instance {
  customer: ICustomerMethods;
  sites: ISiteMethods;
  places: IPlaceMethods;
  parseLink(options: { url: string }): Promise<LinkDetails>;
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
}