import { WebPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';
import type { FlybuyPickupPlugin } from './definitions';
import type { FlyBuyOrder, OrderOptions, OrderState, CustomerState, PickupType } from '../definitions';

export class FlybuyPickupWeb extends WebPlugin implements FlybuyPickupPlugin {

  private notSupported(method: string): never {
    throw this.unimplemented(`${method} is not supported on web.`);
  }

  // ── Orders ───────────────────────────────────

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

  // ── Events ───────────────────────────────────

  async addListener(
    _eventName: 'ordersUpdated' | 'orderUpdated' | 'ordersError',
    _listenerFunc: (data: any) => void
  ): Promise<PluginListenerHandle> {
    return this.notSupported('addListener');
  }
}