# React Native vs Capacitor Plugin Comparison
 
This document compares the Flybuy React Native wrapper (`iris-react-native`) with the Capacitor plugin (`flybuy-capacitor`) to help teams migrating between frameworks or maintaining both.
 
---
 
## Module Structure
 
| | React Native | Capacitor |
|---|---|---|
| Core (customer, sites, places, links) | `@radiusnetworks/react-native-flybuy-core` | `flybuy-capacitor` |
| Pickup (orders) | `@radiusnetworks/react-native-flybuy-pickup` | `flybuy-capacitor/pickup` |
| Notify (campaigns) | `@radiusnetworks/react-native-flybuy-notify` | `flybuy-capacitor/notify` |
| LiveStatus | `@radiusnetworks/react-native-flybuy-livestatus` | Native only (AppDelegate / MainApplication) |
 
---
 
## Imports
 
**React Native:**
```typescript
import { Customer, Orders, Sites, Places, Links } from '@radiusnetworks/react-native-flybuy-core';
import { onPermissionChanged } from '@radiusnetworks/react-native-flybuy-pickup';
import { sync, configure } from '@radiusnetworks/react-native-flybuy-notify';
```
 
**Capacitor:**
```typescript
import { Flybuy } from 'flybuy-capacitor';
import { FlybuyPickup } from 'flybuy-capacitor/pickup';
import { FlybuyNotify } from 'flybuy-capacitor/notify';
```
 
---
 
## Customer Methods
 
| Method | React Native | Capacitor | Notes |
|---|---|---|---|
| Get current customer | `Customer.getCurrentCustomer()` | `Flybuy.getCurrentCustomer()` | ✅ Same |
| Create anonymous | `Customer.createCustomer(customerInfo)` | `Flybuy.createCustomer({customerInfo, termsOfService, ageVerification})` | Capacitor requires explicit consent flags |
| Login with email | `Customer.login(email, password)` | `Flybuy.login({customerInfo, email, password, termsOfService, ageVerification})` | Capacitor requires customerInfo and consent |
| Login with token | `Customer.loginWithToken(token)` | `Flybuy.loginWithToken({token})` | RN positional, Capacitor options object |
| Logout | `Customer.logout()` | `Flybuy.logout()` | ✅ Same |
| Update customer | `Customer.updateCustomer(customerInfo)` | `Flybuy.updateCustomer({customerInfo})` | RN positional, Capacitor options object |
| Sign up | `Customer.signUp(email, password)` | `Flybuy.signUp({email, password})` | RN positional, Capacitor options object |
 
---
 
## Sites Methods
 
| Method | React Native | Capacitor | Notes |
|---|---|---|---|
| Fetch by region | `Sites.fetchSitesByRegion({per, page, region})` | `Flybuy.fetchSitesByRegion({latitude, longitude, radiusMeters})` | Different shape — RN uses `CircularRegion` object, Capacitor uses flat params |
| Fetch by partner ID | `Sites.fetchSiteByPartnerIdentifier({partnerIdentifier})` | `Flybuy.fetchSiteByPartnerIdentifier({partnerIdentifier})` | ✅ Same |
| Fetch near place | `Sites.fetchSitesNearPlace(place, distance)` | `Flybuy.fetchSitesNearPlace({place, radius})` | RN positional, Capacitor options object |
| Fetch all | `Sites.fetchAllSites()` | — | Not in Capacitor (deprecated in SDK) |
| Fetch by query | `Sites.fetchSitesByQuery({query, page})` | — | Not in Capacitor (deprecated in SDK) |
 
---
 
## Places Methods
 
| Method | React Native | Capacitor | Notes |
|---|---|---|---|
| Suggest | `Places.suggest(keyword, {latitude, longitude})` | `Flybuy.placesSuggest({query, options?})` | Different naming; RN `suggest`, Capacitor `placesSuggest` |
| Retrieve | `Places.retrieve(place)` | `Flybuy.placesRetrieve({place})` | Returns coordinates only in Capacitor |
 
---
 
## Orders Methods
 
| Method | React Native | Capacitor | Notes |
|---|---|---|---|
| Fetch orders | `Orders.fetchOrders()` | `FlybuyPickup.fetchOrders()` | ✅ Same (different module) |
| Get cached orders | — | `FlybuyPickup.getOrders({filter?})` | Capacitor-only; returns from cache |
| Fetch by redemption code | `Orders.fetchOrderByRedemptionCode(redemCode)` | `FlybuyPickup.fetchOrderByRedemptionCode({redemptionCode})` | RN positional, Capacitor options object |
| Create by site ID | `Orders.createOrder({siteId, pid, ...})` | `FlybuyPickup.createOrderBySiteID({siteID, orderOptions})` | Different shape |
| Create by partner ID | `Orders.createOrder({sitePartnerIdentifier, orderPid, ...})` | `FlybuyPickup.createOrderBySitePartnerIdentifier({sitePartnerIdentifier, orderOptions})` | Different shape |
| Claim order | `Orders.claimOrder(redeemCode, customerInfo, pickupType?)` | `FlybuyPickup.claimOrder({redemptionCode, orderOptions})` | RN positional + separate customerInfo; Capacitor uses OrderOptions |
| Update order state | `Orders.updateOrderState(orderId, state)` | `FlybuyPickup.updateOrderState({orderID, state})` | RN positional, Capacitor options object |
| Update customer state | `Orders.updateOrderCustomerState(orderId, state)` | `FlybuyPickup.updateOrderCustomerState({orderID, customerState, spotIdentifier?})` | Capacitor combines spot into same call |
| Update customer state + spot | `Orders.updateOrderCustomerStateWithSpot(orderId, state, spot)` | `FlybuyPickup.updateOrderCustomerState({orderID, customerState, spotIdentifier})` | Capacitor uses single method |
| Update pickup method | `Orders.updatePickupMethod(orderId, options)` | `FlybuyPickup.updatePickupMethod({orderID, pickupType, ...})` | RN positional, Capacitor options object |
| Rate order | `Orders.rateOrder(orderId, rating, comments)` | `FlybuyPickup.rateOrder({orderID, rating, comments?, categories?})` | Capacitor adds `categories` |
 
---
 
## Events
 
| Event | React Native | Capacitor | Notes |
|---|---|---|---|
| Order updated | `addOrderUpdatedListener(callback)` | `FlybuyPickup.addListener('orderUpdated', callback)` | Standard Capacitor listener pattern |
| Orders updated | — | `FlybuyPickup.addListener('ordersUpdated', callback)` | Capacitor-only batch event |
| Orders error | — | `FlybuyPickup.addListener('ordersError', callback)` | Capacitor-only |
 
---
 
## Notify Methods
 
| Method | React Native | Capacitor | Notes |
|---|---|---|---|
| Configure | `configure(bgTaskIdentifier?)` | Native only (AppDelegate / MainApplication) | Not JS-callable in Capacitor |
| Sync | `sync(force)` | `FlybuyNotify.sync({force})` | ✅ Same intent |
| Update template content | — | `FlybuyNotify.updateCustomTemplateContent({content})` | Capacitor-only |
| Clear notifications | `clearNotifications()` | — | Removed (deprecated in SDK, no replacement) |
| Create for sites in region | `createForSitesInRegion(region, notification)` | — | Removed (deprecated in SDK) |
| Permission changed | `onPermissionChanged()` | Native only | Not JS-callable in Capacitor |
 
---
 
## Native-Only (Not JS-Callable)
 
These exist in the RN wrapper as JS methods but are handled natively in Capacitor:
 
| Method | RN Module | Capacitor Equivalent |
|---|---|---|
| `updatePushToken(token)` | Core | Firebase service / AppDelegate |
| `handleRemoteNotification(data)` | Core | Firebase service / AppDelegate |
| `handleNotification(data)` | Core | MainActivity / AppDelegate |
| `startObserver()` / `stopObserver()` | Core | Plugin `load()` lifecycle |
| `parseReferrerUrl(referrerUrl)` | Core (Android only) | MainActivity |
| `onPermissionChanged()` | Pickup, Notify | Native permission callbacks |
| `configure(bgTaskIdentifier?)` | Notify | AppDelegate / MainApplication |
| LiveStatus `configure(icon, ...)` | LiveStatus | AppDelegate / MainApplication |
 
---
 
## Parameter Style Differences
 
The most common source of migration errors. RN uses positional arguments; Capacitor uses options objects.
 
**React Native:**
```typescript
Orders.claimOrder('ABC123', { name: 'Marty McFly' }, 'curbside');
Orders.updateOrderCustomerState(123, 'en_route');
Orders.updateOrderCustomerStateWithSpot(123, 'waiting', '4B');
```
 
**Capacitor:**
```typescript
FlybuyPickup.claimOrder({
  redemptionCode: 'ABC123',
  orderOptions: { customerName: 'Marty McFly', pickupType: 'curbside' }
});
FlybuyPickup.updateOrderCustomerState({ orderID: 123, customerState: 'en_route' });
FlybuyPickup.updateOrderCustomerState({ orderID: 123, customerState: 'waiting', spotIdentifier: '4B' });
```
 
---
 
## Return Value Differences
 
RN returns values directly; Capacitor wraps them in named objects.
 
**React Native:**
```typescript
const customer = await Customer.getCurrentCustomer(); // Customer | null
const orders = await Orders.fetchOrders();            // IOrder[]
```
 
**Capacitor:**
```typescript
const { customer } = await Flybuy.getCurrentCustomer(); // { customer: FlyBuyCustomer | null }
const { orders } = await FlybuyPickup.fetchOrders();    // { orders: FlyBuyOrder[] }
```