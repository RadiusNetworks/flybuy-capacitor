// ─────────────────────────────────────────────────────────────────────────────
// MyFirebaseMessagingService.kt — Host App Firebase Push Handling
// ─────────────────────────────────────────────────────────────────────────────
//
// Copy this into your Ionic/Capacitor host app.
// Register in AndroidManifest.xml inside <application>:
//
//   <service
//       android:name=".MyFirebaseMessagingService"
//       android:exported="false">
//       <intent-filter>
//           <action android:name="com.google.firebase.MESSAGING_EVENT" />
//       </intent-filter>
//   </service>
//
// Also call FlyBuyCore.getInstance().customer.logout { ... } with
// FirebaseMessaging.getInstance().deleteToken() on user logout.
//
// ─────────────────────────────────────────────────────────────────────────────

package com.yourapp

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.radiusnetworks.flybuy.sdk.FlyBuyCore

class MyFirebaseMessagingService : FirebaseMessagingService() {

    // Called for every incoming push message.
    // Pass ALL messages to Flybuy — it filters internally and only
    // processes messages relevant to the SDK.
    override fun onMessageReceived(message: RemoteMessage) {
        FlyBuyCore.onMessageReceived(message.data, null)
    }

    // Called when the device push token changes.
    // Flybuy needs the latest token to send order updates.
    override fun onNewToken(token: String) {
        FlyBuyCore.onNewPushToken(token)
    }
}
