Branch iOS SDK change log

- v0.12.11
  * Support for Carthage sub modules
  * Fix for few swift compatibility issues

- v0.12.10
  * Fix for issue causing initsession hang on cold start from universal link
  * Adding few crash protection
  * Removing BUO nullable fields  

- v0.12.9
  * Fixing the time delay for strong match check using SVC

- v0.12.8
  * Changes for supporting latest xcode updates
  * Content Discovery feature
  * Fix for an iOS 7 crash issue

- v0.12.7
  * iOS 10 Spotlight indexing support
  * iMessage extensions support for deep linking and BUO
  * retrieve content type in BUO from dictionary

- v0.12.6
  * Remove debug gesture
  * Better instrumentation on retries
  * Add checksumming to the release procedure
  * Fix Branch & Mopub Fabric header conflict 
  * Nullability and nonnull support for Swift
  * Add campaign to link properties
  * iOS 10 optimizations

- v0.12.5
  * New Testbed App!
  * fix module.map path on Carthage project
  * ability to whitelist URI schemes

- v0.12.4 
  * setDebug must be called on getInstance. It's no longer a static method.
  * referral code and promo code methods are no longer available
  * action count methods are no longer available
  * getReferralUrl removed - please migrate to BUO
  * getContentUrl removed - please migrate to BUO
  * BUO showShareSheet andCallback method deprecated - migrate to showShareSheet callback.
  * App ID removed - please migrate to using Branch Key
  * Handle iOS 10 returning all-zeros IDFA when limiting ad tracking

- v0.12.3
  * Fabric Answers integration
  * Swift Testbed
  * Retry in poor network conditions 
  * Fix for Facebook calling openUrl from within the app
  * Fix Fabric headers conflict
  * Simplify Carthage project
  * Fix framework headers visibility issue with BranchView

- v0.12.2
  * better error handling for 500s
  * check for Facebook deferred app links on the client
  * sanity checks for strong_match url
  * send vendor_id in requests
  * provide .podspec to install SDK without AdSupport framework

- v0.12.1
  * removed unnecessary device info
  * error handling for Branch Views
  * support for new Branch domains

- v0.12.0
  * ability to suppress warning logs
  * fix NSURLSession checks
  * add SDK support for application landing pages
  * Fabric integration
  * TestBed app cleanup

- v0.11.18
  * prevent against future crashes on wrong installParams format

- v0.11.17
  * Carthage support
  * account for different anchors on iPad for share sheet
  * add canonincal ID and URL to spotlight index
  * change matchDuration parameter sent to the backend
  * fix unit tests
  * URL encoding for iOS 6

- v0.11.16
  * increased timeout for SFSafariViewController
  * removed init session methods that do not use launchOptions

- v0.11.15
  * improvements on share sheet
  * Slack bug fix
  * new completion handler for share sheet

- v0.11.14
  * include channel when generating spotlight link
  * push notification support
  * workaround for Facebook sometimes returning NO from didFinishLaunching
  * spotlight IDs optionally returned in indexing callbacks
  * added ability to have custom parameters appear in deeplink data for debugging
  * removed fftl 
  * added externalIntentURI to capture referrals

- v0.11.13
  * fixed race condition when Universal Link is clicked (introduced in 0.11.12 only)
  * updated TestBed app to use Branch Universal Object
  * made cookie-based matching safer (thanks to @joshuafeldman)

- v0.11.12
  * After initsession, close the app if now in background
  * Add support for setting email subject when using BranchUniversalObject
  * Client network timeouts increased
  * Pass content expiration date through to spotlight index
  * Warn if easy deeplinking view controllerdoes not implement configure ControlWithData:
  * Set email subject on share sheet
  * 100% matching prototype. Woo!
  * BRanchUniversalObject with only canonical url allowed
  * Update register-view call so it's no longer a flat object  
  * Fix debug tests
  * Fix setUserUrl capitalization
  * TeamID can be gotten from plist or original way
  * allow users to specify branch_universal_link_domains

- v0.11.11
  * fixed dashboard debug mode for iOS 9
  * fixed default value of userIdentity
  * fixed race condition in PrefererencesHelper
  * fixed race condition in initSession
  * added check for non-nil sessionID

- v0.11.10
  * revert fix for race condition until we can test with more partners

- v0.11.9
  * updated BNCServerInterface tests
  * deprecated promo/referral codes
  * added logoutWithCallback method
  * small change to update session id if necessary
  * fixed race condition if SDK methods are invoked while initSession is in progress
  * updated license
  * added missing headers to framework
  * made BUO share sheet method safe for iPads

- v0.11.8
  * added support for the brand new BranchUniversalObject
    * easy tracking of views on content
    * easy creation of links
    * easy sharing
    * easy listing for Spotlight search
  * fixed bugs / made additions for debug mode
  * squashed annoying warnings that some users saw
  * safer unarchiving of saved info (BNCPreferenceHelper) 

- v0.11.6
  * fix race condition if certain methods are invoked before initSession

- v0.11.5
  * makes cookie-based matching using SFSafariViewController opt-in
  * BranchActivityItemProvider now provides link even if initSession fails multiple times
  * BranchDeepLinkingController now includes a check for modal already presented
  * Fixed small memory leaks created by NSURLSession
  * Changed podspec to remove optional links to iOS 9 frameworks
  * Fixed race conditions caused by initializing the SDK on framework load

- v0.11.4
  * removes the need to include CoreSpotlight
  * addresses issues where SDK would not compile against iOS 8.x base SDKs

- v0.11.3
  * fixed more compatibility issues with older iOS versions

- v0.11.2
  * fixes issue for compiling against iOS 6 and iOS 7

- v0.11.1
  * fixed issue where Universal Links are not handled on cold launch
  * removed deprecated methods
  * podspec allows iOS 6

- v0.11.0
  * iOS 9 compatibility. Makes use of CoreSpotlight, SafariServices, etc.
  * Universal Links
  * Indexing content with Spotlight
  * Various improvements

- v0.10.9
  * Renaming `completionDelegate` to `deepLinkingCompletionDelegate` to avoid conflicts with Apple internals.
  * Changing behavior of `isReferrable` to default to true, unless otherwise specified.

- v0.10.8
  * Thanks @allenhsu for noticing and fixing our character encoding length issues!
  * Less verbose logging for queue processing failures.

- v0.10.7
  * Updating debugging requests so they aren't persisted (and aren't loaded) from the queue.

- v0.10.6
  * Fix queue handling for any future issues with requests.
  * Allow for NSTimeInterval instead of NSInteger timeout / retry, for subsequent preferences.
  * Fix missing symbols on iOS 6.
  * Fix an issue with the fallback url creation for shortUrl.
  * Added a ton of tests around the new requests.
  * Fixing deployment target for Branch library.

- v0.10.5
  * Added back BranchGetAppListRequest class too

- v0.10.4
  * Added back BranchUpdateAppListRequest class to fix crashes

- v0.10.3
  * Removing the AppListing functionality, as it is explicitly disallowed on iOS 9.
  * Updating behavior for when installParams / getFirstReferringParams are set. Specifically, it will now only happen when
    * If isReferrable is false, it will not be set.
    * If the session data returned from the API call is empty, it will not be set.
    * If the session data is not from a link click, it will not be set.
    * If the request is an open request, it will only be set if install params are empty.  

- v0.10.2
  * Fixing potential for bad types to come through in UserIdentity (number rather than string).

- v0.10.1
  * Fixing a bad key check in the CreditHistory callback, allowing NSNulls through.

- v0.10.0
  * Adding an automatic deep linking feature, allowing devs to register a controller to be displayed based on keys in the open dictionary.
  * Adding a delegate to the `BranchActivityItemProvider`, allowing devs to override link items based on selected sharing network.
  * Fixed a potential crash w/ the persistence item if modified while saving.
  * Deprecated some additional functions for the `getActivityItem:` methods, trying to move away from using "and" in method naming.
  * Adding a check to prevent requests from being made when the SDK is in a bad state (missing device fingerprint or session).
  * Exposed the `BNCConfig` header in the framework.

- v0.9.3
  * Clearing the Link Cache on logout; links shouldn't be shared between users.

- v0.9.2
  * Fixing check for isReferrable. No longer automatically setting to true for `handleDeepLink:`, and checking against `@0` since `nil` isn't possible.
  * Making PreferenceHelper and non-singleton, and saving to file instead of using NSUserDefaults which made us prone to having our info wiped out from under us. Also keeping objects in memory, so that they don't need to be retrieved for each reference.

- v0.9.1
  * Fixing an issue with archiving requests when requests are allocated too early.
  * Fixing a potential crash while calling close without a session.
  * Lots of readme updates.

- v0.9.0
  * Renaming Referral Codes to Promo Codes.

- v0.8.4
  * Fixing an issue with getShortUrl.

- v0.8.3
  * Fixing an issue with Open / Install requests losing their callbacks, but not being dequeued.
  * Updating default config values (timeout: 5, retries: 1, sleep: 0).
  * Cleaning up the Link Cache.
  * Adding Bundle ID to Open / Install requests.
  * Fixing an issue causing double escaped params.

- v0.8.2
  * Fix issue with callbacks being lost on some of the internal requests.
  * Fix issue with old requests not fitting the new request format, causing crsahes.

- v0.8.1
  * Fix potential for bad reference when no callback is provided to `redeemRewards` call.

- v0.8.0
  * Split up all requests into their own classes to make them unit testable.
  * Replace base64 implementation which could potentially crash.
  * Remove most logic from the PreferenceHelper.

- v0.7.8
  * Removing source attribute from `encodeDictionaryToJsonString`, only added to short url generation now.
  * Fixing bad content type in `prepareGetRequest`.
  * Creating scripts for an automated release process.
  * Fixing a bad callback in `processNextQueueItem`, potentially causing a crash.
  * Adding and documenting all of the new constants added in the Branch initSession callback.

- v0.7.7 Changing the time for update state checks to give better install attribution.

- v0.7.6
  * Exposing `isUserIdentified` to allow devs to understand if Branch has a User Identity set.
  * Removing all instances of `bnc_no_value` from the SDK.
  * Creating a separate error code for Branch being down vs a request failing
  * Fixing a bug where and error would cause queue processing to stop, and pending request to be failed.

- v0.7.5 Prefixing constants to avoid collisions with other frameworks.

- v0.7.4
  * Fixing key usage throughout the SDK. When you call `getTestInstance` or `getInstance:`, the proper key will now make it through to requests.
  * Cleaning up debug logic internally. The static usage of `setDebug` is now deprecated, please move toward using the instance method.

- v0.7.3
  * Fixing Branch down check (>= 500 instead of > 500).
  * Removing tag from all BNCServerInterface methods.
  * Moving request retry delay off the main thread.
  * Removing committed CocoaPod files.

- v0.7.2
  * Added docs to the header, compatible with [AppleDoc](https://github.com/tomaz/appledoc) and available on [cocoadocs.org](cocoadocs.org).
  * De-coupling all of the Branch dependencies to make them injectable. This will significantly improve test stability.
  * Clearing all Branch related items when the Branch key being used in the app changes. This prevents invalid items from making it to the server.

- v0.7.1 Adding a missing item to the pod spec headers.

- v0.7.0
  * Large rewrite of the internals of Branch.m to make things more stable, predictable, readable, and maintainable.
  * Added callbacks to the `redeemRewards` methods.
  * Updating Queue persistence to be non-immediate. Rather than persisting to disk on every change, it persists after time has elapsed to prevent hanging issues when in a loop.
  * Making errors more specific -- now you actually get the error message back, instead of a generic one.
  * Fixing issue with BranchActivityItemProvider when using the Twitter share sheet.
  * Removing temporary backwards compat typedefs.

- v0.6.3:
  * Addressing an issue identified by iHeartRadio where decoding a JSON string could cause crashes.
  * Adding the ability to opt out of the app list check.

- v0.6.2:
  * Fixing an issue with the newest Facebook app not working with the ShareSheet unless an NSURL is present.
  * Fixing user url generation for `getShortUrl` failure callbacks.
  * Fixing a couple issues with `setDebug`.
  * Using NS_ENUMs.
  * Removing remaining internal `setUriScheme` code.
  * Cleaning up update state logic.

- v0.6.1: Issue with requests in the queue having their data updated when they were immutable. Updating BNCServerRequest interface to prevent this from happening in the future.

- v0.6.0: We have deprecated the use of `bnc_app_key` and are now using `branch_key`, which can be obtained in the settings page of your Dashboard. The replacement in the SDK should happen in the plist, as well as in `+(Branch *)getInstance:(NSString *)branchKey;` if necessary.

- v0.5.9: Revert of the URI Scheme updates.

- v0.5.8:
  * Fixing an issue with the creation of NSError userInfo dictionaries.
  * Updating behavior of URI Scheme detection -- you should now name the scheme you want to use "io.branch.sdk." The previous behavior will be maintained for some time.
  * You can additionally specify which scheme to use via `[[Branch getInstance] setUriScheme:@"myapp://"]`

- v0.5.7: Adding handling around the Facebook share sheet to prevent incorrect link clicks. Removing `branch_key` warning message.

- v0.5.6: Issue sending proper update to server if isReferrable not set

- v0.5.5: Reverting branch_key change until server component is updated. Fixing an issue with getShortUrl failures causing crashes.

- v0.5.4: A large number of changes have been included in this version, but all are backwards compatibile.
  * Retry Number has been added to all requests, so that the server is able to differentiate.
  * Organization of some of the encoding methods in the repository has been centralized.
  * Fixed an encoding bug with empty param dictionaries and arrays.
  * A couple of encoding issues were fixed, and a large number of tests have been added.
  * Perhaps most importantly, the `branch_key` is now replacing the `bnc_app_key` and `app_id` items. For now, both will continue to work, but the non-`branch_key` items are deprecated, and will be removed with `0.6.0`.
  * The presence of `app_id` and `branch_key` has been ensured across all requests, no longer piecemeal.

- v0.5.3: Follow up to 0.5.2, now looks at Documents directory creation date and considers this to be the original app install date

- v0.5.2: Recent iOS update resets bundle file creation date on update, messing with our update/install detection method

- v0.5.1: Fixed request black hole after initSession failed

- V0.5.0: Removed Default URL argument from BranchActivityItemProvider, and replaced with an automatically generated long URL placeholder

- v0.4.8: Fixed hashing issue on very long NSString in link caching

- v0.4.7: Rework of `BNCServerInterface encodePostToUniversalString:needSource:`

- v0.4.6.2: Added unit tests

- V0.4.6.1: Exposed duration in getShortUrl for tuning link click match duration

- V0.4.6: Added API Key to GET requests; Fixed iOS 6 issue in UIActivityItemProvider

- v0.4.5: Double check all delegates when switching to main queue

- v0.4.4: Fixed potential deadlock issue

- v0.4.3: Added app listing

- v0.4.2: Added API's for getShortURL Synchrnously

- v0.4.1: Added BranchActivityItemProvider

- v0.4.0: Made CoreTelephony framework optional, Added UIActivityView item provider, Make debug clear device fingerprint

- v0.3.102: Caching short url's for the same parameters

- v0.3.101: Completely fixed nil sessionparamLoadCallback issue

- v0.3.100: Fixed nilling sessionparamLoadCallback in initSession

- v0.3.99: Restored old way to specify app key in app delegate as an alternative to plist

- v0.3.98: Removed swizzling for debugger

- v0.3.97: Moved app key to plist

- v0.3.96: Added adTrackingSafe

- v0.3.95: Added BNCDebugging category to framework

- v0.3.91: Added getters/setters for API timeout, retryInterval and retryCount

- v0.3.90: Added more info to debug connect

- v0.3.81: Fixed encoding exception in BNCServerRequestQueue

- v0.3.80: Better handling of incorrect keys; only queue requests if init succeeded

- v0.3.7: Added handleFailure for non init

- v0.3.6: Added Branch remote debug feature

- v0.3.5: Fixed race condition

- v0.3.4: Added BranchLinkType to getShortURL

- v0.3.3: Reimplemented apply referral code

- v0.3.2: Added API for referral code

- v0.3.1: Fixed synchronization issue in queue persistence

- v0.3.0: Added NSError to callbacks
