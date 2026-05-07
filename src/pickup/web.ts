import { WebPlugin } from '@capacitor/core';
import type { FlybuyPickupPlugin } from './definitions';
import type { FlyBuyOrder, OrderOptions, OrderState, CustomerState, PickupType } from '../definitions';

export class FlybuyPickupWeb extends WebPlugin implements FlybuyPickupPlugin {

  private notSupported(method: string): never {
    throw this.unimplemented(`${method} is not supported on web.`);
  }

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

  async updateOrderState(_options: { orderID: number; state: OrderState | string }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updateOrderState');
  }

  async updateOrderCustomerState(_options: { orderID: number; customerState: CustomerState | string; spotIdentifier?: string }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updateOrderCustomerState');
  }

  async updatePickupMethod(_options: { orderID: number; pickupType: PickupType | string; customerCarType?: string; customerCarColor?: string; customerLicensePlate?: string; handoffVehicleLocation?: string }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('updatePickupMethod');
  }

  async rateOrder(_options: { orderID: number; rating: number; comments?: string; categories?: string[] }): Promise<{ order: FlyBuyOrder }> {
    return this.notSupported('rateOrder');
  }
}