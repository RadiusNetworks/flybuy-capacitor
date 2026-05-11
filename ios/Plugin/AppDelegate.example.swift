// ─────────────────────────────────────────────────────────────────────────────
// AppDelegate.swift — Host App Setup
// ─────────────────────────────────────────────────────────────────────────────
//
// Copy this configuration into your Ionic/Capacitor host app's AppDelegate.swift.
// Flybuy MUST be configured at launch — it cannot be initialized from JavaScript.
//
// ─────────────────────────────────────────────────────────────────────────────

import UIKit
import CoreLocation
import UserNotifications
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
            // .setSecondaryAppTokenKey("SECOND_APP_TOKEN_HERE")  // optional
            // .setDeferredLocationTracking(true)                  // optional
            .build()
        FlyBuy.Core.configure(withOptions: configOptions)

        // ── Pickup Module ────────────────────────────────────────────────────
        FlyBuyPickup.Manager.shared.configure()

        // ── Live Status Module (optional — iOS 16.2+ only) ───────────────────
        // if #available(iOS 16.2, *) {
        //     let liveStatusOptions = LiveStatusOptions.Builder()
        //         .setIconName("your_icon_asset_name")
        //         .setStatusTintColor(.blue)
        //         .setStatusTintColorDarkMode(.white)
        //         .build()
        //     FlyBuyLiveStatusManager.shared.configure(withOptions: liveStatusOptions)
        // }

        // ── Notify Module (optional) ─────────────────────────────────────────
        FlyBuyNotify.Manager.shared.configure(
            bgTaskIdentifier: "com.yourapp.flybuy.refresh"
        )

        // ── Presence Module (optional) ───────────────────────────────────────
        // FlyBuyPresence.Manager.shared.configure("YOUR-PRESENCE-UUID-HERE")

        // ── Push Notifications ───────────────────────────────────────────────
        // IMPORTANT: delegate must be set before app finishes launching
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted { print("Notification permission granted") }
        }
        application.registerForRemoteNotifications()
        // If using Firebase, also set: Messaging.messaging().delegate = self

        // ── Location Permissions ─────────────────────────────────────────────
        // Can also be requested later, e.g. before claiming an order
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()

        return true
    }

    // ── Push Token Handlers ───────────────────────────────────────────────────

    // APNs direct — send device token to Flybuy
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

    // Handles silent APN push messages (Pickup module)
    // NOTE: distinct from handleNotification() below
    //   handleRemoteNotification → silent APN push messages
    //   handleNotification       → user tapping a displayed notification
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        FlyBuy.Core.handleRemoteNotification(userInfo)
        completionHandler(.newData)
    }

    // ── Universal Links (Deep Linking) ────────────────────────────────────────
    // Prerequisites:
    //   1. Add Associated Domains entitlement in Xcode: applinks:pickup.example.com
    //   2. Contact your Flybuy Customer Success rep to configure your domain.

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let handled = ApplicationDelegateProxy.shared.application(
            application,
            continue: userActivity,
            restorationHandler: restorationHandler
        )
        if handled { return true }

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return false
        }

        return handleIncomingLink(incomingURL)
    }

    @discardableResult
    private func handleIncomingLink(_ url: URL) -> Bool {
        let linkDetails = FlyBuy.Links.parse(url: url)

        switch linkDetails.type {
        case .redemption:
            if let code = linkDetails.params["r"] {
                // Send redemption code to Ionic layer
                // NotificationCenter.default.post(name: .flybuyRedemption, object: code)
            }
        case .dineIn:
            // Hold onto linkDetails.orderOptions to create an order
            // NotificationCenter.default.post(name: .flybuyDineIn, object: linkDetails)
            break
        default:
            return false
        }

        return true
    }

    // ── Capacitor ────────────────────────────────────────────────────────────

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }
}

// ── UNUserNotificationCenterDelegate ─────────────────────────────────────────
// Required for Notify module.

extension AppDelegate: UNUserNotificationCenterDelegate {

    // Called when user taps a notification.
    // Uses FlyBuyNotify.Manager.shared.handleNotification() for Notify campaigns.
    // NOTE: distinct from handleRemoteNotification() above.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let metadata = FlyBuyNotify.Manager.shared.handleNotification(response),
           !metadata.isEmpty {
            // Flybuy Notify campaign notification — use metadata to navigate
        } else {
            // Handle other app notifications here
        }
        completionHandler()
    }

    // Required to receive notifications while app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .alert])
    }

    // Support campaign content background updates on iOS < 13
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        FlyBuyNotify.Manager.shared.performFetchWithCompletionHandler(completionHandler)
    }
}

// ── Firebase Messaging Delegate (use instead of APNs direct above) ────────────
// extension AppDelegate: MessagingDelegate {
//     func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//         guard let token = fcmToken else { return }
//         FlyBuy.Core.updatePushToken(token)
//     }
// }
