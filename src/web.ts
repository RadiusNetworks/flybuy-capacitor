import { WebPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';
import type { FlybuyPlugin } from './definitions';
import type {
  FlyBuyCustomer,
  CustomerInfo,
  FlyBuySite,
  FlyBuyPlace,
  PlaceSuggestOptions,
  LinkDetails,
  FlyBuyOrder,
  OrderOptions,
  OrderState,
  CustomerState,
  PickupType,
} from './definitions';

export class FlybuyWeb extends WebPlugin implements FlybuyPlugin {

  private notSupported(method: string): never {
    throw this.unimplemented(`${method} is not supported on web.`);
  }

  // ── Customer ─────────────────────────────────

  async getCurrentCustomer(_options: { appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer | null }> {
    return this.notSupported('getCurrentCustomer');
  }

  async createCustomer(_options: { customerInfo: CustomerInfo; termsOfService: boolean; ageVerification: boolean; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('createCustomer');
  }

  async login(_options: { email: string; password: string; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('login');
  }

  async loginWithToken(_options: { token: string; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('loginWithToken');
  }

  async logout(_options: { appAuthId: string | null }): Promise<void> {
    return this.notSupported('logout');
  }

  async updateCustomer(_options: { customerInfo: CustomerInfo; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('updateCustomer');
  }

  async signUp(_options: { email: string; password: string; appAuthId: string | null }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('signUp');
  }

  // ── Sites ─────────────────────────────────────

  async fetchSitesByRegion(_options: { latitude: number; longitude: number; radiusMeters: number; appAuthId: string | null }): Promise<{ sites: FlyBuySite[] }> {
    return this.notSupported('fetchSitesByRegion');
  }

  async fetchSiteByPartnerIdentifier(_options: { partnerIdentifier: string; appAuthId: string | null }): Promise<{ site: FlyBuySite }> {
    return this.notSupported('fetchSiteByPartnerIdentifier');
  }

  async fetchSitesNearPlace(_options: { place: FlyBuyPlace; radius: number; appAuthId: string | null }): Promise<{ sites: FlyBuySite[] }> {
    return this.notSupported('fetchSitesNearPlace');
  }

  // ── Places ────────────────────────────────────

  async placesSuggest(_options: { query: string; options?: PlaceSuggestOptions; appAuthId: string | null }): Promise<{ places: FlyBuyPlace[] }> {
    return this.notSupported('placesSuggest');
  }

  async placesRetrieve(_options: { place: FlyBuyPlace; appAuthId: string | null }): Promise<{ place: FlyBuyPlace }> {
    return this.notSupported('placesRetrieve');
  }

  // ── Links ─────────────────────────────────────

  async parseLink(_options: { url: string }): Promise<LinkDetails> {
    return this.notSupported('parseLink');
  }

  // ── Orders ────────────────────────────────────

  async fetchOrders(_options: { appAuthId: string | null }): Promise<{ orders: FlyBuyOrder[] }> {
    return this.notSupported('fetchOrders');
  }

  async getOrders(_options: { filter?: 'all' | 'open' | 'closed'; appAuthId: string | null }): Promise<{ orders: FlyBuyOrder[] }> {
    return this.notSupported('getOrders');
  }

  async fetchOrderByRedemptionCode(_options: { redemptionCode: string; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('fetchOrderByRedemptionCode');
  }

  async createOrderBySiteID(_options: { siteID: number; orderOptions: OrderOptions; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('createOrderBySiteID');
  }

  async createOrderBySitePartnerIdentifier(_options: { sitePartnerIdentifier: string; orderOptions: OrderOptions; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('createOrderBySitePartnerIdentifier');
  }

  async claimOrder(_options: { redemptionCode: string; orderOptions: OrderOptions; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('claimOrder');
  }

  async updateOrderState(_options: { orderID: number; state: OrderState | string; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updateOrderState');
  }

  async updateOrderCustomerState(_options: { orderID: number; customerState: CustomerState | string; spotIdentifier?: string; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updateOrderCustomerState');
  }

  async updatePickupMethod(_options: { orderID: number; pickupType: PickupType | string; customerCarType?: string; customerCarColor?: string; customerLicensePlate?: string; handoffVehicleLocation?: string; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updatePickupMethod');
  }

  async rateOrder(_options: { orderID: number; rating: number; comments?: string; categories?: string[]; appAuthId: string | null }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('rateOrder');
  }

  // ── Events ────────────────────────────────────

  async addListener(
    _eventName: 'ordersUpdated' | 'orderUpdated' | 'ordersError',
    _listenerFunc: (data: any) => void
  ): Promise<PluginListenerHandle> {
    return this.notSupported('addListener');
  }
}