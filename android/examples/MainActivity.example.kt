// ─────────────────────────────────────────────────────────────────────────────
// MainActivity.kt — Host App Deep Link + Notification Handling
// ─────────────────────────────────────────────────────────────────────────────
//
// Copy this into your Ionic/Capacitor host app's MainActivity.
//
// Prerequisites:
//   1. Add intent filters to AndroidManifest.xml for your Flybuy domain:
//
//      <intent-filter android:autoVerify="true">
//          <action android:name="android.intent.action.VIEW" />
//          <category android:name="android.intent.category.DEFAULT" />
//          <category android:name="android.intent.category.BROWSABLE" />
//          <data android:scheme="https" android:host="pickup.example.com" />
//      </intent-filter>
//
//      For NFC + dine-in short links, also add:
//      <intent-filter android:autoVerify="true" tools:ignore="UnusedAttribute">
//          <action android:name="android.nfc.action.NDEF_DISCOVERED" />
//          <action android:name="android.intent.action.VIEW" />
//          <category android:name="android.intent.category.DEFAULT" />
//          <category android:name="android.intent.category.BROWSABLE" />
//          <data android:scheme="https" android:host="pickup.example.com"
//                android:pathPrefix="/s/123/d/" />
//      </intent-filter>
//
//   2. Contact your Flybuy Customer Success rep to configure your domain.
//
// ─────────────────────────────────────────────────────────────────────────────

package com.yourapp

import android.content.Intent
import android.net.Uri
import android.nfc.NfcAdapter
import android.os.Bundle
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.getcapacitor.BridgeActivity
import com.radiusnetworks.flybuy.sdk.FlyBuyCore
import com.radiusnetworks.flybuy.sdk.notify.NotifyManager
import com.radiusnetworks.flybuy.sdk.links.FlyBuyLinks
import com.radiusnetworks.flybuy.sdk.notify.NotifyManager

class MainActivity : BridgeActivity() {

    private var referrerClient: InstallReferrerClient? = null
    private var lastDeepLinkUri: Uri? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ── Notifications ────────────────────────────────────────────────────
        handleNotification(intent)

        // ── Deep Links ───────────────────────────────────────────────────────
        handleDeepLink(intent, intent.data)

        // ── Deferred Deep Links (Install Referrer) ───────────────────────────
        // Handles the case where the app was installed via a Flybuy smart banner link
        referrerClient = InstallReferrerClient.newBuilder(this).build()
        referrerClient?.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                when (responseCode) {
                    InstallReferrerClient.InstallReferrerResponse.OK -> {
                        referrerClient?.installReferrer?.installReferrer?.let { referrerUrl ->
                            FlyBuyLinks.parseReferrerUrl(referrerUrl)?.let {
                                handleDeepLink(null, Uri.parse(it.url))
                            }
                        }
                    }
                    else -> { /* Feature not supported or unavailable */ }
                }
            }

            override fun onInstallReferrerServiceDisconnected() {}
        })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotification(intent)
        handleDeepLink(intent, intent.data)
    }

    // ── Notification Handling ─────────────────────────────────────────────────

    private fun handleNotification(intent: Intent?) {
        intent?.let {
            // NotifyManager handles campaign notifications (Notify module)
            val notifyMetadata = NotifyManager.getInstance().handleNotification(it)
            if (notifyMetadata != null) {
                // Flybuy Notify campaign notification — use metadata to navigate
                // Example: bridge?.triggerWindowJSEvent("flybuyNotification", notifyMetadata.toString())
            } else {
                // Also check FlyBuyCore for other Flybuy notification types
                FlyBuyCore.handleNotification(it)
            }
        }
    }

    // ── Deep Link Handling ────────────────────────────────────────────────────

    private fun handleDeepLink(intent: Intent?, uri: Uri?) {
        // Guard against onNewIntent being called twice with the same URI
        if (uri == null || uri == lastDeepLinkUri) return
        lastDeepLinkUri = uri

        val isDeepLink = intent?.action == Intent.ACTION_VIEW &&
                intent.hasCategory(Intent.CATEGORY_BROWSABLE)
        val isNfc = intent?.action == NfcAdapter.ACTION_NDEF_DISCOVERED

        if (!isDeepLink && !isNfc && intent != null) return

        val linkDetails = FlyBuyLinks.parse(uri.toString())

        when (linkDetails.type.name.lowercase()) {
            "redemption" -> {
                val code = linkDetails.params?.get("r")
                if (code != null) {
                    // Send redemption code to Ionic layer
                    // bridge?.triggerWindowJSEvent("flybuyRedemption", "\"$code\"")
                }
            }
            "dinein" -> {
                // Hold onto linkDetails to create order later
                // bridge?.triggerWindowJSEvent("flybuyDineIn", linkDetails.url)
            }
        }
    }
}
