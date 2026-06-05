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

  // ── Sites ────────────────────────────────────

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

  // ── Deep Links ────────────────────────────────

  async parseLink(_options: { url: string }): Promise<LinkDetails> {
    return this.notSupported('parseLink');
  }
}