// ─────────────────────────────────────────────────────────────────────────────
// AppDelegate.swift — Host App Setup
// ─────────────────────────────────────────────────────────────────────────────
//
// Copy this configuration into your Ionic/Capacitor host app's AppDelegate.swift.
// Flybuy MUST be configured at launch — it cannot be initialized from JavaScript.
//
// Required imports depend on which modules your app uses:
//   - FlyBuyPickup    → for curbside / in-store pickup
//   - FlyBuyPresence  → for Bluetooth presence detection
//   - FlyBuyNotify    → for geofence / beacon notifications
//   - FlyBuyLiveStatus → for iOS Live Activities (requires iOS 16.2+)
//
// ─────────────────────────────────────────────────────────────────────────────

import UIKit
import Capacitor
import FlyBuy
import FlyBuyPickup
import FlyBuyNotify
// import Firebase         // Uncomment if using Firebase push
// import FlyBuyPresence   // Uncomment if using Presence module
// import FlyBuyLiveStatus // Uncomment if using Live Status module

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ── Flybuy Core ──────────────────────────────────────────────────────
        let configOptions = ConfigOptions.Builder(token: "YOUR_APP_TOKEN_HERE")
            // Optional: multi-project support
            // .setSecondaryAppTokenKey("SECOND_APP_TOKEN_HERE")
            // Optional: defer location tracking until customer taps "I'm on my way"
            // .setDeferredLocationTracking(true)
            .build()
        FlyBuy.Core.configure(withOptions: configOptions)

        // ── Pickup Module (required for order pickup flows) ──────────────────
        FlyBuyPickup.Manager.shared.configure()

        // ── Live Status Module (optional — iOS 16.2+ only) ───────────────────
        // Requires:
        //   1. Widget Extension target in Xcode with "Include Live Activity" enabled
        //   2. FlyBuyLiveStatus added to both app target and widget extension target
        //   3. NSSupportsLiveActivities = true in Info.plist
        //   4. FlyBuyWidget() added to your WidgetBundle
        //
        // if #available(iOS 16.2, *) {
        //     let liveStatusOptions = LiveStatusOptions.Builder()
        //         .setIconName("your_icon_asset_name")
        //         .setStatusTintColor(.blue)           // light mode
        //         .setStatusTintColorDarkMode(.white)  // dark mode
        //         .build()
        //     FlyBuyLiveStatusManager.shared.configure(withOptions: liveStatusOptions)
        // }

        // ── Notify Module (optional — for geofence/beacon notifications) ─────
        // Replace with your app's unique background task identifier
        FlyBuyNotify.Manager.shared.configure(
            bgTaskIdentifier: "com.yourapp.flybuy.refresh"
        )

        // ── Presence Module (optional — for Bluetooth presence) ──────────────
        // Replace with your Presence UUID from the Flybuy dashboard
        // FlyBuyPresence.Manager.shared.configure("YOUR-PRESENCE-UUID-HERE")

        // ── Push Notifications ───────────────────────────────────────────────
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        application.registerForRemoteNotifications()
        // If using Firebase, also set: Messaging.messaging().delegate = self

        return true
    }

    // ── Push Notification Handlers ───────────────────────────────────────────

    // APNs direct — send device token to Flybuy
    // Also needed when using Firebase with method swizzling disabled
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // If using Firebase, uncomment this and remove the lines below:
        // Messaging.messaging().apnsToken = deviceToken

        let hexToken = deviceToken.map { String(format: "%02hhx", $0) }.joined()
        #if DEBUG
        FlyBuy.Core.updatePushToken("dev:" + hexToken)
        #else
        FlyBuy.Core.updatePushToken(hexToken)
        #endif
    }

    // Handle incoming background push notifications
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        FlyBuy.Core.handleRemoteNotification(userInfo)
        completionHandler(.newData)
    }

    // ── Capacitor ────────────────────────────────────────────────────────────

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        return ApplicationDelegateProxy.shared.application(
            application,
            continue: userActivity,
            restorationHandler: restorationHandler
        )
    }
}

// ── Firebase Messaging Delegate ───────────────────────────────────────────────
// Use this extension INSTEAD of the APNs didRegisterForRemoteNotificationsWithDeviceToken
// handler above if you are using Firebase for push notifications.
//
// extension AppDelegate: MessagingDelegate {
//     func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//         guard let token = fcmToken else { return }
//         FlyBuy.Core.updatePushToken(token)
//     }
// }