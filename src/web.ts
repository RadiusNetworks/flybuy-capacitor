import { WebPlugin } from '@capacitor/core';
import type {
  FlybuyPlugin,
  FlyBuyCustomer,
  FlyBuySite,
  FlyBuyPlace,
  CustomerInfo,
  PlaceSuggestOptions,
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

  async login(_options: { customerInfo: CustomerInfo; email: string; password: string; termsOfService: boolean; ageVerification: boolean }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('login');
  }

  async loginWithToken(_options: { token: string }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('loginWithToken');
  }

  async logout(): Promise<void> {
    return this.notSupported('logout');
  }

  async updateCustomer(_options: { customerInfo: CustomerInfo }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('updateCustomer');
  }

  async signUp(_options: { email: string; password: string }): Promise<{ customer: FlyBuyCustomer }> {
    return this.notSupported('signUp');
  }

  // ── Sites ────────────────────────────────────

  async fetchSitesByRegion(_options: { latitude: number; longitude: number; radiusMeters: number }): Promise<{ sites: FlyBuySite[] }> {
    return this.notSupported('fetchSitesByRegion');
  }

  async fetchSiteByPartnerIdentifier(_options: { partnerIdentifier: string }): Promise<{ site: FlyBuySite }> {
    return this.notSupported('fetchSiteByPartnerIdentifier');
  }

  async fetchSitesNearPlace(_options: { place: FlyBuyPlace; radius: number }): Promise<{ sites: FlyBuySite[] }> {
    return this.notSupported('fetchSitesNearPlace');
  }

  // ── Places ────────────────────────────────────

  async placesSuggest(_options: { query: string; options?: PlaceSuggestOptions }): Promise<{ places: FlyBuyPlace[] }> {
    return this.notSupported('placesSuggest');
  }

  async placesRetrieve(_options: { place: FlyBuyPlace }): Promise<{ place: FlyBuyPlace }> {
    return this.notSupported('placesRetrieve');
  }

  // ── Deep Links ────────────────────────────────

  async parseLink(_options: { url: string }): Promise<LinkDetails> {
    return this.notSupported('parseLink');
  }
}