// ─────────────────────────────────────────────────────────────────────────────
// MyApplication.kt — Host App Setup
// ─────────────────────────────────────────────────────────────────────────────
//
// Copy this configuration into your Ionic/Capacitor host app's Application class.
// Flybuy MUST be configured at launch — it cannot be initialized from JavaScript.
//
// 1. Create this file in your host app if it doesn't exist
// 2. Register it in AndroidManifest.xml:
//      <application android:name=".MyApplication" ...>
// 3. Add Google API key to AndroidManifest.xml (required by Flybuy SDK):
//      <meta-data
//          android:name="com.google.android.geo.API_KEY"
//          android:value="YOUR_GOOGLE_API_KEY"/>
// 4. Register MyFirebaseMessagingService in AndroidManifest.xml:
//      <service
//          android:name=".MyFirebaseMessagingService"
//          android:exported="false">
//          <intent-filter>
//              <action android:name="com.google.firebase.MESSAGING_EVENT" />
//          </intent-filter>
//      </service>
//
// ─────────────────────────────────────────────────────────────────────────────

package com.yourapp

import android.app.Application
import com.google.firebase.messaging.FirebaseMessaging
import com.radiusnetworks.flybuy.sdk.FlyBuyCore
import com.radiusnetworks.flybuy.sdk.pickup.PickupManager
// import com.radiusnetworks.flybuy.sdk.notify.NotifyManager       // Uncomment if using Notify
// import com.radiusnetworks.flybuy.sdk.presence.PresenceManager   // Uncomment if using Presence
// import com.radiusnetworks.flybuy.sdk.livestatus.LiveStatusManager  // Uncomment if using Live Status
// import com.radiusnetworks.flybuy.sdk.livestatus.LiveStatusOptions

class MyApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // ── Flybuy Core ──────────────────────────────────────────────────────
        val configOptions = com.radiusnetworks.flybuy.sdk.ConfigOptions.Builder("YOUR_APP_TOKEN_HERE")
            // Optional: multi-project support
            // .setSecondaryAppTokenKey("SECOND_APP_TOKEN_HERE")
            // Optional: defer location tracking until customer taps "I'm on my way"
            // .setDeferredLocationTrackingEnabled(true)
            .build()
        FlyBuyCore.configure(this, configOptions)

        // ── Pickup Module (required for order pickup flows) ──────────────────
        PickupManager.getInstance().configure(this)

        // ── Live Status Module (optional) ────────────────────────────────────
        // val liveStatusOptions = LiveStatusOptions.Builder()
        //     .setStatusTintColor(ContextCompat.getColor(this, R.color.liveStatusTintLight))
        //     .setStatusTintColorDarkMode(ContextCompat.getColor(this, R.color.liveStatusTintDark))
        //     .build()
        // LiveStatusManager.getInstance().configure(this, liveStatusOptions)

        // ── Notify Module (optional) ─────────────────────────────────────────
        // NotifyManager.getInstance().configure(this)

        // ── Presence Module (optional) ───────────────────────────────────────
        // PresenceManager.getInstance().configure(this, "YOUR-PRESENCE-UUID-HERE")

        // ── Push Token ───────────────────────────────────────────────────────
        // Refresh push token on app start
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
