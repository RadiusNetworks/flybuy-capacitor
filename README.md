# flybuy-capacitor

Capacitor plugin wrapping the [Flybuy SDK](https://www.radiusnetworks.com/developers/flybuy) by Radius Networks.

Supports iOS and Android. Exposes the Pickup module's Orders, Customer, and Sites managers to JavaScript/TypeScript.

---

## Installation

```bash
npm install flybuy-capacitor
npx cap sync
```

---

## iOS Setup

### 1. Add Flybuy SDK via Swift Package Manager

In Xcode, go to **File → Add Package Dependencies** and enter:

```
https://github.com/RadiusNetworks/flybuy-ios
```

Add the modules your app needs: `FlyBuyPickup`, `FlyBuyNotify`, `FlyBuyPresence`, `FlyBuyLiveStatus`.

### 2. Configure in AppDelegate

Copy the contents of `ios/Plugin/AppDelegate.example.swift` into your host app's `AppDelegate.swift`. Flybuy **must** be configured at launch — it cannot be initialized from JavaScript.

```swift
import FlyBuy
import FlyBuyPickup

func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    let configOptions = ConfigOptions.Builder(token: "YOUR_APP_TOKEN")
        .build()
    FlyBuy.Core.configure(withOptions: configOptions)
    FlyBuyPickup.Manager.shared.configure()
    return true
}
```

### 3. Info.plist Permissions

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>To accurately locate you for order delivery</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>To communicate via Bluetooth for an order at the store</string>
```

### 4. Background Modes (Xcode → Signing & Capabilities)

- Location updates
- Background fetch
- Remote notifications

---

## Android Setup

> Android implementation coming soon.

---

## Usage

```typescript
import { Flybuy, CustomerState, OrderState, FlybuyErrorCode } from 'flybuy-capacitor';

// ── Listen for order updates ──────────────────────────────────
const listener = await Flybuy.addListener('orderUpdated', ({ order }) => {
  console.log('Order updated:', order.state, order.customerState);
});

// Clean up
listener.remove();

// ── Customer ──────────────────────────────────────────────────────────

// The SDK persists the customer session until the app is uninstalled
// or logoutCustomer() is called -- no token storage needed for typical use.
const { customer } = await Flybuy.getCurrentCustomer();

if (!customer) {
  // Create anonymous customer (consent must be obtained via UI first)
  await Flybuy.createCustomer({
    customerInfo: { name: 'Marty McFly', phone: '555-5555' },
    termsOfService: true,
    ageVerification: true,
  });
}

// Note: loginWithToken() is only needed if syncing a Flybuy customer
// across multiple devices via your own backend.


// ── Order Redemption Flow ─────────────────────────────────────

// 1. Fetch order to show details
const { order } = await Flybuy.fetchOrderByRedemptionCode({
  redemptionCode: 'ABC123',
});

// 2. If already claimed, go to status screen
if (order.redeemedAt) {
  navigateTo('order-status', order);
  return;
}

// 3. Claim the order
const { order: claimedOrder } = await Flybuy.claimOrder({
  redemptionCode: 'ABC123',
  orderOptions: {
    customerName: 'Marty McFly',
    customerCarColor: 'Silver',
    customerCarType: 'DeLorean',
    customerCarPlate: 'OUTATIME',
    pickupType: 'curbside',
  },
});

// 4. Start location tracking
await Flybuy.updateOrderCustomerState({
  orderID: claimedOrder.id,
  customerState: CustomerState.EnRoute,
});

// ── Order Status Screen ───────────────────────────────────────

function getOrderViewState(order) {
  if (!order.redeemedAt)           return 'unclaimed';
  if (order.state === 'cancelled') return 'cancelled';
  if (!order.isOpen)               return 'completed';
  if (order.customerState === CustomerState.Waiting ||
      order.customerState === CustomerState.Arrived) return 'onsite';
  return 'enroute';
}

// I'm waiting — with optional spot identifier
await Flybuy.updateOrderCustomerState({
  orderID: order.id,
  customerState: CustomerState.Waiting,
  spotIdentifier: '4B',  // max 35 chars
});

// I have my order
await Flybuy.updateOrderCustomerState({
  orderID: order.id,
  customerState: CustomerState.Completed,
});

// Rate the order
await Flybuy.rateOrder({
  orderID: order.id,
  rating: 5,
  comments: 'Great service',
  categories: ['speed', 'quality'],
});

// ── Error Handling ────────────────────────────────────────────

try {
  await Flybuy.fetchOrderByRedemptionCode({ redemptionCode: 'INVALID' });
} catch (err: any) {
  switch (err.code) {
    case FlybuyErrorCode.OrdersError:
      console.error('Orders error:', err.message);
      break;
    case FlybuyErrorCode.ApiError:
      console.error('API error, status:', err.data?.statusCode);
      break;
    default:
      console.error('Unknown error:', err.message);
  }
}
```

---

## API

See [src/definitions.ts](src/definitions.ts) for the full TypeScript interface including all methods, options, and return types.

### Orders
| Method | Description |
|---|---|
| `fetchOrders()` | Fetch orders from server, update cache |
| `getOrders(filter?)` | Return cached orders (all / open / closed) |
| `fetchOrderByRedemptionCode(...)` | Fetch unclaimed order by redemption code |
| `createOrderBySiteID(...)` | Create order using Flybuy site ID |
| `createOrderBySitePartnerIdentifier(...)` | Create order using site partner identifier |
| `claimOrder(...)` | Claim order and start location tracking |
| `updateOrderState(...)` | Update merchant-facing order state |
| `updateOrderCustomerState(...)` | Update customer state (optionally with spot identifier) |
| `updatePickupMethod(...)` | Update pickup type and vehicle info |
| `rateOrder(...)` | Submit order rating with optional comments and categories |

### Customer
| Method | Description |
|---|---|
| `getCurrentCustomer()` | Get current logged-in customer or null |
| `createCustomer(...)` | Create anonymous customer |
| `createCustomerWithLogin(...)` | Create customer with email/password |
| `loginWithToken(...)` | Log in with stored customer token |
| `logoutCustomer()` | Clear customer and order data |
| `updateCustomer(...)` | Update customer info |
| `signUpCustomer(...)` | Link email/password to anonymous customer |

### Sites
| Method | Description |
|---|---|
| `fetchAllSites()` | Fetch all sites |
| `fetchSitesByQuery(...)` | Search sites by query string |
| `fetchSitesByRegion(...)` | Fetch sites within a geographic radius |
| `fetchSiteByPartnerIdentifier(...)` | Fetch a single site by partner identifier |

### Events
| Event | Payload |
|---|---|
| `ordersUpdated` | `{ orders: FlyBuyOrder[] }` |
| `orderUpdated` | `{ order: FlyBuyOrder }` |
| `ordersError` | `{ error: string }` |

---

## License

MIT © Radius Networks
