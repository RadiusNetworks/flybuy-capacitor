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

## Imports & Instance Pattern

Both SDKs now use the same `getInstance` pattern for Core and Pickup.

**React Native:**
```typescript
import { getInstance } from '@radiusnetworks/react-native-flybuy-core';
import { getPickupInstance } from '@radiusnetworks/react-native-flybuy-pickup';
import { sync, configure } from '@radiusnetworks/react-native-flybuy-notify';

const core = getInstance();          // primary
const core = getInstance('139');     // secondary project

const pickup = getPickupInstance();
```

**Capacitor:**
```typescript
import { getInstance } from 'flybuy-capacitor';
import { getPickupInstance } from 'flybuy-capacitor/pickup';
import { FlybuyNotify } from 'flybuy-capacitor/notify';

const core = getInstance();          // primary
const core = getInstance('139');     // secondary project

const pickup = getPickupInstance();
```

> **Note:** Notify does not support multi-project in either SDK — it always uses the singleton manager.

---

## Customer Methods

| Operation | React Native | Capacitor | Notes |
|---|---|---|---|
| Get current customer | `core.customer.getCurrent()` | `core.customer.getCurrent()` | ✅ Identical |
| Create anonymous | `core.customer.create(customerInfo)` | `core.customer.create({customerInfo, termsOfService, ageVerification})` | Capacitor requires explicit consent flags |
| Login with email | `core.customer.login(email, password)` | `core.customer.login({email, password})` | RN positional, Capacitor options object |
| Login with token | `core.customer.loginWithToken(token)` | `core.customer.loginWithToken({token})` | RN positional, Capacitor options object |
| Logout | `core.customer.logout()` | `core.customer.logout()` | ✅ Identical |
| Update customer | `core.customer.update(customerInfo)` | `core.customer.update({customerInfo})` | RN positional, Capacitor options object |
| Sign up | `core.customer.signUp(email, password)` | `core.customer.signUp({email, password})` | RN positional, Capacitor options object |

---

## Sites Methods

| Operation | React Native | Capacitor | Notes |
|---|---|---|---|
| Fetch by region | `core.sites.fetchByRegion(region, siteOptions?)` | `core.sites.fetchByRegion({latitude, longitude, radiusMeters})` | RN uses `CircularRegion` object, Capacitor uses flat params |
| Fetch by partner ID | `core.sites.fetchByPartnerIdentifier(pid, siteOptions?)` | `core.sites.fetchByPartnerIdentifier({partnerIdentifier})` | RN positional, Capacitor options object |
| Fetch near place | `core.sites.fetchNearPlace(place, distance)` | `core.sites.fetchNearPlace({place, radius})` | RN positional, Capacitor options object |
| Fetch nearby | `core.sites.fetchNearby(distance, siteOptions?)` | — | Not in Capacitor |
| Check if on site | `core.sites.checkIfOnSite()` | — | Not in Capacitor |

---

## Places Methods

| Operation | React Native | Capacitor | Notes |
|---|---|---|---|
| Suggest | `core.places.suggest(keyword, options)` | `core.places.suggest({query, options?})` | RN positional, Capacitor options object |
| Retrieve | `core.places.retrieve(place)` | `core.places.retrieve({place})` | Returns coordinates only in Capacitor |

---

## Orders Methods

| Operation | React Native | Capacitor | Notes |
|---|---|---|---|
| Fetch orders | `pickup.orders.fetch()` | `pickup.orders.fetch()` | ✅ Identical |
| Get cached orders | — | `pickup.orders.get({filter?})` | Capacitor-only; returns from cache |
| Fetch by redemption code | `pickup.orders.fetchByRedemptionCode(code)` | `pickup.orders.fetchByRedemptionCode({redemptionCode})` | RN positional, Capacitor options object |
| Create by site ID | `pickup.orders.createWithSiteId(siteId, orderOptions)` | `pickup.orders.createWithSiteId({siteID, orderOptions})` | RN positional, Capacitor options object |
| Create by partner ID | `pickup.orders.createWithSitePartnerIdentifier(pid, orderOptions)` | `pickup.orders.createWithSitePartnerIdentifier({sitePartnerIdentifier, orderOptions})` | RN positional, Capacitor options object |
| Claim order | `pickup.orders.claim(redeemCode, orderOptions)` | `pickup.orders.claim({redemptionCode, orderOptions})` | RN positional, Capacitor options object |
| Update order state | `pickup.orders.updateState(orderId, state)` | `pickup.orders.updateState({orderID, state})` | RN positional, Capacitor options object |
| Update customer state | `pickup.orders.updateCustomerState(orderId, state, spot?)` | `pickup.orders.updateCustomerState({orderID, customerState, spotIdentifier?})` | RN positional, Capacitor options object |
| Update pickup method | `pickup.orders.updatePickupMethod(orderId, options)` | `pickup.orders.updatePickupMethod({orderID, pickupType, ...})` | RN positional, Capacitor options object |
| Rate order | `pickup.orders.rateOrder(orderId, rating, comments, categories?)` | `pickup.orders.rateOrder({orderID, rating, comments?, categories?})` | RN positional, Capacitor options object |

---

## Events

| Event | React Native | Capacitor | Notes |
|---|---|---|---|
| Order updated | `addOrderUpdatedListener(callback)` | `pickup.addListener('orderUpdated', callback)` | Standard Capacitor listener pattern |
| Orders updated | — | `pickup.addListener('ordersUpdated', callback)` | Capacitor-only batch event |
| Orders error | — | `pickup.addListener('ordersError', callback)` | Capacitor-only |

---

## Notify Methods

| Operation | React Native | Capacitor | Notes |
|---|---|---|---|
| Configure | `configure(bgTaskIdentifier?)` | Native only (AppDelegate / MainApplication) | Not JS-callable in Capacitor |
| Sync | `sync(force)` | `FlybuyNotify.sync({force})` | Same intent, Capacitor uses options object |
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

## Return Value Differences

RN returns values directly; Capacitor wraps them in named objects.

**React Native:**
```typescript
const customer = await core.customer.getCurrent(); // Customer | null
const orders = await pickup.orders.fetch();        // IOrder[]
```

**Capacitor:**
```typescript
const { customer } = await core.customer.getCurrent(); // { customer: FlyBuyCustomer | null }
const { orders } = await pickup.orders.fetch();        // { orders: FlyBuyOrder[] }
```

---

## Multi-Project Support

Both SDKs support multiple Flybuy projects via `getInstance(appAuthId?)`. Pass `null` or omit for the primary project.

```typescript
// React Native
const primary = getInstance();
const secondary = getInstance('139');

// Capacitor — identical pattern
const primary = getInstance();
const secondary = getInstance('139');
```

> **Notify** does not support multi-project in either SDK.