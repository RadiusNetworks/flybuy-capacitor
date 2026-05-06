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
//
// ─────────────────────────────────────────────────────────────────────────────

package com.yourapp

import android.app.Application
import androidx.core.content.ContextCompat
import com.radiusnetworks.flybuy.sdk.FlyBuyCore
import com.radiusnetworks.flybuy.sdk.pickup.PickupManager
import com.radiusnetworks.flybuy.sdk.notify.NotifyManager
// import com.radiusnetworks.flybuy.sdk.presence.PresenceManager     // Uncomment if using Presence
// import com.radiusnetworks.flybuy.sdk.livestatus.LiveStatusManager  // Uncomment if using Live Status
// import com.radiusnetworks.flybuy.sdk.livestatus.LiveStatusOptions  // Uncomment if using Live Status

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
        // Requires live-status gradle dependency
        //
        // val liveStatusOptions = LiveStatusOptions.Builder()
        //     .setStatusTintColor(ContextCompat.getColor(this, R.color.liveStatusTintLight))
        //     .setStatusTintColorDarkMode(ContextCompat.getColor(this, R.color.liveStatusTintDark))
        //     .build()
        // LiveStatusManager.getInstance().configure(this, liveStatusOptions)
        //
        // To override the notification icon, add drawable res named: ic_stat_location_service

        // ── Notify Module (optional — for geofence/beacon notifications) ─────
        // Requires notify gradle dependency
        //
        // NotifyManager.getInstance().configure(this)

        // ── Presence Module (optional — for Bluetooth presence) ──────────────
        // Requires presence gradle dependency
        //
        // PresenceManager.getInstance().configure(this, "YOUR-PRESENCE-UUID-HERE")
    }
}
