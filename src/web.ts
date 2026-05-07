import { WebPlugin } from '@capacitor/core';
import type {
  FlybuyPlugin,
  FlyBuyCustomer,
  FlyBuySite,
  CustomerInfo,
  LinkDetails,
} from './definitions';

export class FlybuyWeb extends WebPlugin implements FlybuyPlugin {

  private notSupported(method: string): never {
    throw this.unimplemented(`${method} is not supported on web.`);
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

  // ── Deep Links ────────────────────────────────

  async parseLink(_options: { url: string }): Promise<LinkDetails> {
    return this.notSupported('parseLink');
  }
}