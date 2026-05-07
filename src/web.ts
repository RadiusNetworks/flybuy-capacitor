import { WebPlugin } from '@capacitor/core';
import type {
  FlybuyPlugin,
  FlyBuyOrder,
  FlyBuyCustomer,
  FlyBuySite,
  OrderOptions,
  CustomerInfo,
  LinkDetails,
} from './definitions';

export class FlybuyWeb extends WebPlugin implements FlybuyPlugin {

  private notSupported(method: string): never {
    throw this.unimplemented(`${method} is not supported on web.`);
  }

  // ── Orders ──────────────────────────────────

  async fetchOrders(): Promise<{ orders: FlyBuyOrder[] }> {
    return this.notSupported('fetchOrders');
  }

  async getOrders(_options?: { filter?: 'all' | 'open' | 'closed' }): Promise<{ orders: FlyBuyOrder[] }> {
    return this.notSupported('getOrders');
  }

  async fetchOrderByRedemptionCode(_options: { redemptionCode: string }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('fetchOrderByRedemptionCode');
  }

  async createOrderBySiteID(_options: { siteID: number; orderOptions: OrderOptions }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('createOrderBySiteID');
  }

  async createOrderBySitePartnerIdentifier(_options: { sitePartnerIdentifier: string; orderOptions: OrderOptions }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('createOrderBySitePartnerIdentifier');
  }

  async claimOrder(_options: { redemptionCode: string; orderOptions: OrderOptions }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('claimOrder');
  }

  async updateOrderState(_options: { orderID: number; state: string }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updateOrderState');
  }

  async updateOrderCustomerState(_options: { orderID: number; customerState: string; spotIdentifier?: string }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updateOrderCustomerState');
  }

  async updatePickupMethod(_options: { orderID: number; pickupType: string; customerCarType?: string; customerCarColor?: string; customerLicensePlate?: string; handoffVehicleLocation?: string }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updatePickupMethod');
  }

  async rateOrder(_options: { orderID: number; rating: number; comments?: string; categories?: string[] }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('rateOrder');
  }

  // ── Customer ─────────────────────────────────

  async getCurrentCustomer(): Promise<{ customer: FlyBuyCustomer | null }> {
    return this.notSupported('getCurrentCustomer');
  }

  async createCustomer(_options: { customerInfo: CustomerInfo; termsOfService: boolean; ageVerification: boolean }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('createCustomer');
  }

  async createCustomerWithLogin(_options: { customerInfo: CustomerInfo; email: string; password: string; termsOfService: boolean; ageVerification: boolean }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('createCustomerWithLogin');
  }

  async loginWithToken(_options: { token: string }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('loginWithToken');
  }

  async logoutCustomer(): Promise<void> {
    return this.notSupported('logoutCustomer');
  }

  async updateCustomer(_options: { customerInfo: CustomerInfo }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('updateCustomer');
  }

  async signUpCustomer(_options: { email: string; password: string }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('signUpCustomer');
  }

  // ── Sites ────────────────────────────────────

  async fetchAllSites(): Promise<{ sites: FlyBuySite[] }> {
    return this.notSupported('fetchAllSites');
  }

  async fetchSitesByQuery(_options: { query: string }): Promise<{ sites: FlyBuySite[] }> {
    return this.notSupported('fetchSitesByQuery');
  }

  async fetchSitesByRegion(_options: { latitude: number; longitude: number; radiusMeters: number }): Promise<{ sites: FlyBuySite[] }> {
    return this.notSupported('fetchSitesByRegion');
  }

  async fetchSiteByPartnerIdentifier(_options: { partnerIdentifier: string }): Promise<{ site: FlyBuySite }> {
    return this.notSupported('fetchSiteByPartnerIdentifier');
  }

  async updateCustomTemplateContent(_options: { content: Record<string, string> }): Promise<void> {
    return this.notSupported('updateCustomTemplateContent');
  }

  async parseLink(_options: { url: string }): Promise<LinkDetails> {
    return this.notSupported('parseLink');
  }
}