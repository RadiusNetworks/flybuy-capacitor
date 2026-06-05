Capacitor plugin wrapping the [Flybuy SDK](https://www.radiusnetworks.com/developers/flybuy) by Radius Networks.

Supports iOS and Android. Exposes the Core, Pickup, and Notify modules to JavaScript/TypeScript.

---

## Installation

This package is distributed via GitHub, not npm.

```bash
# Latest from main
npm install github:RadiusNetworks/flybuy-capacitor
npx cap sync

# Pin to a specific release tag (recommended for production)
npm install github:RadiusNetworks/flybuy-capacitor#v0.1.5
npx cap sync
```

The `prepare` script compiles TypeScript automatically on install — no pre-built `dist/` folder needs to be committed.

---

## iOS Setup

### 1. Configure in AppDelegate

Copy the contents of `ios/Plugin/AppDelegate.example.swift` into your host app's `AppDelegate.swift`. Flybuy **must** be configured at launch — it cannot be initialized from JavaScript.

```swift
import FlyBuy
import FlyBuyPickup
import FlyBuyNotify

func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    let configOptions = ConfigOptions.Builder(token: "YOUR_APP_TOKEN")
        .build()
    FlyBuy.Core.configure(withOptions: configOptions)
    FlyBuyPickup.Manager.shared.configure()
    FlyBuyNotify.Manager.shared.configure(bgTaskIdentifier: "com.yourapp.flybuy.refresh")
    UNUserNotificationCenter.current().delegate = self
    return true
}
```

### 2. Info.plist Permissions

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>To accurately locate you for order delivery</string>

<!-- Required only if using Presence module -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>To communicate via Bluetooth for an order at the store</string>
```

### 3. Background Modes (Xcode → Signing & Capabilities)

Enable **Background Modes** and check:
- Location updates
- Background fetch
- Remote notifications

---

## Android Setup

### 1. Configure Application class

Create (or update) your `Application` class. Copy `android/examples/MyApplication.example.kt` as a starting point. Flybuy **must** be configured at launch — it cannot be initialized from JavaScript.

Register it in `AndroidManifest.xml`:

```xml
<application android:name=".MainApplication" ...>
```

```kotlin
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val configOptions = ConfigOptions.Builder("YOUR_APP_TOKEN_HERE").build()
        FlyBuyCore.configure(this, configOptions)
        PickupManager.getInstance().configure(this)
        NotifyManager.getInstance().configure(this)
        updatePushToken()
    }

    private fun updatePushToken() {
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                task.result?.let { FlyBuyCore.onNewPushToken(it) }
            }
        }
    }
}
```

### 2. Firebase Messaging Service

Copy `android/examples/MyFirebaseMessagingService.example.kt` into your app and register it in `AndroidManifest.xml`:

```xml
<service
    android:name=".FlyBuyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### 3. Google Maps API Key

Add to `AndroidManifest.xml` inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_API_KEY"/>
```

### 4. Deep Links and Notifications

Copy `android/examples/MainActivity.example.kt` into your app for deep link and notification handling. See the file for `AndroidManifest.xml` intent filter setup.

---

## Usage

```typescript
import { getInstance, CustomerState, FlybuyErrorCode } from 'flybuy-capacitor';
import { getPickupInstance } from 'flybuy-capacitor/pickup';
import { FlybuyNotify } from 'flybuy-capacitor/notify';

// ── Get scoped instances ──────────────────────────────────────

const core = getInstance();           // primary project
const pickup = getPickupInstance();   // primary project

// Multi-project support: pass appAuthId for a secondary project
// const core = getInstance('139');
// const pickup = getPickupInstance('139');

// ── Listen for order updates ──────────────────────────────────

const listener = await pickup.addListener('orderUpdated', ({ order }) => {
  console.log('Order updated:', order.state, order.customerState);
});

// Clean up
listener.remove();

// ── Customer ──────────────────────────────────────────────────

// The SDK persists the customer session until the app is uninstalled
// or logout() is called -- no token storage needed for typical use.
const { customer } = await core.customer.getCurrent();

if (!customer) {
  // Create anonymous customer (consent must be obtained via UI first)
  await core.customer.create({
    customerInfo: { name: 'Guest', phone: '' },
    termsOfService: true,
    ageVerification: true,
  });
}

// ── Order Redemption Flow ─────────────────────────────────────

// 1. Fetch order to show details
const { order } = await pickup.orders.fetchByRedemptionCode({ redemptionCode: 'ABC123' });

// 2. If already claimed, go to status screen
if (order.redeemedAt) {
  navigateTo('order-status', order);
  return;
}

// 3. Claim the order
const { order: claimedOrder } = await pickup.orders.claim({
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
await pickup.orders.updateCustomerState({
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
await pickup.orders.updateCustomerState({
  orderID: order.id,
  customerState: CustomerState.Waiting,
  spotIdentifier: '4B',
});

// I have my order
await pickup.orders.updateCustomerState({
  orderID: order.id,
  customerState: CustomerState.Completed,
});

// Rate the order
await pickup.orders.rateOrder({
  orderID: order.id,
  rating: 5,
  comments: 'Great service',
  categories: ['speed', 'quality'],
});

// ── Sites ─────────────────────────────────────────────────────

const { sites } = await core.sites.fetchByRegion({
  latitude: 37.7749,
  longitude: -122.4194,
  radiusMeters: 50000,
});

const { site } = await core.sites.fetchByPartnerIdentifier({
  partnerIdentifier: 'my-store-123',
});

// Search for places then fetch nearby sites
const { places } = await core.places.suggest({ query: 'Coffee' });
const { place } = await core.places.retrieve({ place: places[0] });
const { sites: nearbySites } = await core.sites.fetchNearPlace({ place, radius: 10000 });

// ── Deep Links ────────────────────────────────────────────────

const link = await core.parseLink({ url: incomingURL });
if (link.type === 'redemption' && link.params?.r) {
  // Handle redemption code
}

// ── Notify ────────────────────────────────────────────────────

// Notify does not support multi-project — always uses the singleton manager
await FlybuyNotify.updateCustomTemplateContent({
  content: {
    name: 'Marty McFly',
    reward_points: '100',
  }
});

await FlybuyNotify.sync({ force: false });

// ── Error Handling ────────────────────────────────────────────

try {
  await pickup.orders.fetchByRedemptionCode({ redemptionCode: 'INVALID' });
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

See [src/definitions.ts](src/definitions.ts) and [src/pickup/definitions.ts](src/pickup/definitions.ts) for the full TypeScript interfaces.

### Core (`flybuy-capacitor`)

Access via `getInstance(appAuthId?)`. Omit `appAuthId` or pass `null` for the primary project.

```typescript
const core = getInstance();        // primary
const core = getInstance('139');   // secondary project
```

#### `core.customer`
| Method | Description |
|---|---|
| `getCurrent()` | Get current logged-in customer or null |
| `create(...)` | Create anonymous customer |
| `login(...)` | Log in with email and password |
| `loginWithToken(...)` | Log in with stored customer token |
| `logout()` | Clear customer and order data |
| `update(...)` | Update customer info |
| `signUp(...)` | Link email/password to anonymous customer |

#### `core.sites`
| Method | Description |
|---|---|
| `fetchByRegion(...)` | Fetch sites within a geographic radius |
| `fetchByPartnerIdentifier(...)` | Fetch a single site by partner identifier |
| `fetchNearPlace(...)` | Fetch sites near a resolved place |

#### `core.places`
| Method | Description |
|---|---|
| `suggest(...)` | Get place suggestions for a keyword |
| `retrieve(...)` | Resolve a place suggestion to full coordinates |

#### `core.parseLink(...)`
Parse a Flybuy URL into type and params.

---

### Pickup (`flybuy-capacitor/pickup`)

Access via `getPickupInstance(appAuthId?)`.

```typescript
const pickup = getPickupInstance();        // primary
const pickup = getPickupInstance('139');   // secondary project
```

#### `pickup.orders`
| Method | Description |
|---|---|
| `fetch()` | Fetch orders from server, update cache |
| `get(options?)` | Return cached orders (all / open / closed) |
| `fetchByRedemptionCode({ redemptionCode })` | Fetch unclaimed order by redemption code |
| `createWithSiteId({ siteID, orderOptions })` | Create order using Flybuy site ID |
| `createWithSitePartnerIdentifier({ sitePartnerIdentifier, orderOptions })` | Create order using site partner identifier |
| `claim({ redemptionCode, orderOptions })` | Claim order and start location tracking |
| `updateState({ orderID, state })` | Update merchant-facing order state |
| `updateCustomerState({ orderID, customerState, spotIdentifier? })` | Update customer state (optionally with spot identifier) |
| `updatePickupMethod({ orderID, pickupType, ... })` | Update pickup type and vehicle info |
| `rateOrder({ orderID, rating, comments?, categories? })` | Submit order rating |

#### Events
| Event | Payload |
|---|---|
| `ordersUpdated` | `{ orders: FlyBuyOrder[] }` |
| `orderUpdated` | `{ order: FlyBuyOrder }` |
| `ordersError` | `{ error: string }` |

---

### Notify (`flybuy-capacitor/notify`)

Notify does not support multi-project — always uses the singleton manager.

| Method | Description |
|---|---|
| `updateCustomTemplateContent(...)` | Inject dynamic values into notification templates |
| `sync(...)` | Sync campaign data with the server |

---

## License

MIT © Radius Networks