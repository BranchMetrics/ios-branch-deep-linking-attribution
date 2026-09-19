//
//  AppDelegate.swift
//  iOSReleaseTest
//
//  Created by Nipun Singh on 2/4/22.
//

import UIKit
import AdSupport
import AppTrackingTransparency
import BranchSDK
import BranchSecureSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Held so the one-shot didBecomeActive observer can be torn down after the ATT prompt fires.
    private var attActivationObserver: NSObjectProtocol?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

       // ATT prompt. Deliberately last: the prompt cannot be presented until the app is active,
       // so this only schedules the request (see requestTrackingAuthorizationWhenActive).
       //  self.requestTrackingAuthorizationWhenActive()
        
       

        BranchLogger.shared().loggingEnabled = true
        BranchLogger.shared().logLevelThreshold = .verbose

        // Point every Branch API call at staging. Must run before getInstance() so the first
        // request already picks it up. No trailing slash — BNCServerAPI appends "/v1/install"
        // etc. directly to this base.

        // Consumer protection: FULL attribution.
        Branch.getInstance().setConsumerProtectionAttributionLevel(.full)

        // partner_data.{snap,fb}.* — exercises nested-object flattening in the canonical string
        // (partner_data has been an empty object in every capture so far). Two partners give the
        // canonical two sibling sub-objects under one parent, i.e. three levels of nesting.
        let hashedValue = "11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"
        Branch.getInstance().addSnapPartnerParameter(withName: "hashed_email_address", value: hashedValue)
        Branch.getInstance().addSnapPartnerParameter(withName: "hashed_phone_number", value: hashedValue)
        Branch.getInstance().addFacebookPartnerParameter(withName: "em", value: hashedValue)
        Branch.getInstance().addFacebookPartnerParameter(withName: "ph", value: hashedValue)
        Branch.getInstance().addFacebookPartnerParameter(withName: "ln", value: hashedValue)

        // metadata.skan_time_window — the SDK formats this with "%f", so it reaches the canonical
        // as the STRING "5184000.000000". That is the §2.4 rule (floats are coerced client-side);
        // a raw Double here would not canonicalize portably across iOS/Android/Go.
        // The setter is deprecated for SKAN 4.0 but is the only way to populate the field.
        Branch.getInstance().setSKAdNetworkCalloutMaxTimeSinceInstall(5_184_000) // 60 days

        // A couple of custom metadata values, merged into the same `metadata` object.
        Branch.getInstance().setRequestMetadataKey("custom_test_key", value: "custom_test_value")
        Branch.getInstance().setRequestMetadataKey("build_flavor", value: "iOSReleaseTest-SPM")

        // web_link_context.{ux_type, url_load_ms} — another nested object in the canonical.
        // There is no Branch.h setter; `addWebUXParams` reads these two preference-helper
        // properties directly and emits the block only when uxType is non-nil.
        //
        // NOTE: the wire key is `url_load_ms`, not `url_load_ts`, and the SDK serializes it from an
        // NSDate via BNCWireFormatFromDate — so it is stored as a Date and sent as epoch millis.
        if let preferenceHelper = BNCPreferenceHelper.sharedInstance() {
            preferenceHelper.uxType = "IN_APP_WEBVIEW"
            preferenceHelper.urlLoadMs = Date(timeIntervalSince1970: 1_234_556.0 / 1000.0) // -> 1234556 ms
        }

        // odm_info + odm_first_open_timestamp. Only emitted when the attribution level is FULL
        // (or uninitialized), which is why this must follow setConsumerProtectionAttributionLevel.
        Branch.setODMInfo("test-odm-aggregate-conversion-info", andFirstOpenTimestamp: Date())

        // dma_eea / dma_ad_personalization / dma_ad_user_data — three top-level BOOLs.
        // These must canonicalize as "1"/"0", never "true"/"false". Mixed values on purpose so a
        // platform that stringifies booleans wrongly produces a visibly different canonical.
        Branch.setDMAParamsForEEA(true, adPersonalizationConsent: false, adUserDataUsageConsent: true)

        // identity — a top-level string on install/open/deeplink.
        //Branch.getInstance().setIdentity("test-user-canonical-1234")

        // Register the fraud defense handler — Branch SDK will call it automatically.
        Branch.getInstance().fraudDefenseHandler = BranchSecureSDK.sharedManager()

        // Request deep link data
        Branch.getInstance().requestDeepLinkData(branchLink: nil) { params, error in
            if let error {
                BranchLogger.shared().logError("Branch requestDeepLinkData failed", error: error)
            } else {
                BranchLogger.shared().logDebug("Branch requestDeepLinkData succeeded — params: \(params ?? [:])", error: nil)
            }
            // /v3/events/standard is the other signed iOS builder (dataForEvent). Fire it after the
            // open so the log contains both signed request types.
            self.logMaximalPurchaseEvent()

            // Same builder, but an event name outside BranchEvent.standardEvents routes to
            // /v3/events/custom instead — so the log covers that endpoint too.
            self.logMaximalCustomEvent()

        }

        return true
    }

    // MARK: - App Tracking Transparency

    /// Schedules the ATT prompt for the first time the app becomes active.
    ///
    /// `requestTrackingAuthorization` is a no-op while the app is still inactive — the system
    /// silently drops the prompt and never invokes the completion — so it cannot be called
    /// directly from `didFinishLaunchingWithOptions`. This app is scene-based, which means
    /// `applicationDidBecomeActive` is never called either, so observe the notification instead.
    private func requestTrackingAuthorizationWhenActive() {
        // Only `.notDetermined` can produce a prompt. Every other status resolves immediately, so
        // report what is already known to Branch and skip the request — requesting anyway would
        // inflate Branch's OPT_IN / OPT_OUT counts (see -handleATTAuthorizationStatus: docs).
        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else {
            BranchLogger.shared().logDebug("[ATT] status already resolved: \(Self.attStatusName(status))", error: nil)
            Branch.getInstance().handleATTAuthorizationStatus(UInt(status.rawValue))
            return
        }

        attActivationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if let observer = self.attActivationObserver {
                NotificationCenter.default.removeObserver(observer)
                self.attActivationObserver = nil
            }
            self.requestTrackingAuthorization()
        }
    }

    private func requestTrackingAuthorization() {
        BranchLogger.shared().logDebug("[ATT] requesting tracking authorization", error: nil)

        ATTrackingManager.requestTrackingAuthorization { status in
            // The completion is not guaranteed to run on the main thread.
            DispatchQueue.main.async {
                BranchLogger.shared().logDebug("[ATT] user responded: \(Self.attStatusName(status))", error: nil)

                // Hand the outcome to Branch so it can measure ATT prompt performance.
                Branch.getInstance().handleATTAuthorizationStatus(UInt(status.rawValue))

                // IDFA is all-zeros until the user authorizes. Logged so the `advertising_ids.idfa`
                // in a signed request can be matched against what the OS actually returned.
                if status == .authorized {
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    BranchLogger.shared().logDebug("[ATT] IDFA: \(idfa)", error: nil)
                }
            }
        }
    }

    private static func attStatusName(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted:    return "restricted"
        case .denied:        return "denied"
        case .authorized:    return "authorized"
        @unknown default:    return "unknown(\(status.rawValue))"
        }
    }

    /// A PURCHASE event populated with every field BranchEvent exposes.
    ///
    /// This is the only signed request that carries an ARRAY (`content_items`), so it is the first
    /// real exercise of index-keyed array flattening in the canonical string
    /// (`content_items.0.$sku=...`). It also carries NSDecimalNumber values (revenue / shipping /
    /// tax / $price) — those must render identically on Android and the Gateway.
    private func logMaximalPurchaseEvent() {
        let metadata = BranchContentMetadata()
        metadata.contentSchema = .commerceProduct
        metadata.quantity = 2
        metadata.price = NSDecimalNumber(string: "19.99")
        metadata.currency = .USD
        metadata.sku = "SKU-1234"
        metadata.productName = "Canonical Test Product"
        metadata.productBrand = "Branch"
        metadata.productCategory = .electronics
        metadata.productVariant = "Blue"
        metadata.condition = .new
        metadata.ratingAverage = 4.5
        metadata.ratingCount = 100
        metadata.customMetadata["item_custom_key"] = "item_custom_value"

        let contentItem = BranchUniversalObject(canonicalIdentifier: "item/1234")
        contentItem.title = "Canonical Test Item"
        contentItem.contentDescription = "Item used for canonical-string testing"
        contentItem.imageUrl = "https://example.com/item.png"
        contentItem.keywords = ["canonical", "test"]
        contentItem.contentMetadata = metadata

        let event = BranchEvent.standardEvent(.purchase)
       // event.alias = "canonical-test-purchase"
        event.transactionID = "txn-0001"
        event.currency = .USD
        event.revenue = NSDecimalNumber(string: "39.98")
        event.shipping = NSDecimalNumber(string: "4.99")
        event.tax = NSDecimalNumber(string: "3.50")
        event.coupon = "TESTCOUPON"
        event.affiliation = "test-affiliation"
        event.eventDescription = "Purchase event carrying every BranchEvent field"
        event.searchQuery = "canonical string"
        event.adType = .banner
        event.contentItems = [contentItem]
        event.customData = [
            "custom_key_1": "custom_value_1",
            "custom_key_2": "custom_value_2",
            "custom_bool_like": "1"
        ]

        BranchLogger.shared().logDebug("[Test] logging maximal PURCHASE event", error: nil)
        event.logEvent()
    }

    /// A custom event populated with every field BranchEvent exposes.
    ///
    /// Identical payload shape to logMaximalPurchaseEvent — the only difference is the event name.
    /// BranchEvent routes on name: anything not in `BranchEvent.standardEvents` hits
    /// /v3/events/custom rather than /v3/events/standard, so this exercises the same signed
    /// builder (dataForEvent) against the other endpoint.
    private func logMaximalCustomEvent() {
        let metadata = BranchContentMetadata()
        metadata.contentSchema = .commerceProduct
        metadata.quantity = 3
        metadata.price = NSDecimalNumber(string: "7.25")
        metadata.currency = .USD
        metadata.sku = "SKU-CUSTOM-9876"
        metadata.productName = "Canonical Custom Product"
        metadata.productBrand = "Branch"
        metadata.productCategory = .electronics
        metadata.productVariant = "Green"
        metadata.condition = .new
        metadata.ratingAverage = 3.5
        metadata.ratingCount = 42
        metadata.customMetadata["item_custom_key"] = "item_custom_value"

        let contentItem = BranchUniversalObject(canonicalIdentifier: "item/9876")
        contentItem.title = "Canonical Custom Item"
        contentItem.contentDescription = "Item used for custom-event canonical-string testing"
        contentItem.imageUrl = "https://example.com/custom-item.png"
        contentItem.keywords = ["canonical", "custom"]
        contentItem.contentMetadata = metadata

        // Must NOT collide with a BranchStandardEvent value, or this would route to
        // /v3/events/standard instead.
        let event = BranchEvent.customEvent(withName: "canonical_test_custom_event")
       // event.alias = "canonical-test-custom"
        event.transactionID = "txn-custom-0001"
        event.currency = .USD
        event.revenue = NSDecimalNumber(string: "21.75")
        event.shipping = NSDecimalNumber(string: "2.99")
        event.tax = NSDecimalNumber(string: "1.75")
        event.coupon = "CUSTOMCOUPON"
        event.affiliation = "test-affiliation"
        event.eventDescription = "Custom event carrying every BranchEvent field"
        event.searchQuery = "canonical string custom"
        event.adType = .interstitial
        event.contentItems = [contentItem]
        event.customData = [
            "custom_key_1": "custom_value_1",
            "custom_key_2": "custom_value_2",
            "custom_bool_like": "0"
        ]

        BranchLogger.shared().logDebug("[Test] logging maximal CUSTOM event", error: nil)
        event.logEvent()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

