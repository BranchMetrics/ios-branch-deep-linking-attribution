Branch iOS SDK Change Log

- v0.18.0
  * Branch links opened via Air Drop now open correctly (GH-#699,#701).
    - Testing notes:  Test this heavily on all the iOS versions, and test opening links when app is
      not running, when it is in background, and when it is in the foreground.  Also, test links
      opened from Notepad, etc.

  * Fixed remote push notification handling (GH-#703,#704).
    - Testing notes: you'll need to send a push notification to the testbed app via
      the `./apns-send-token` script.

  * Fixed a race condition on startup while getting the browser string (GH-#700,#702).
    - Testing notes: To reproduce, turn on the thread sanitizer, remove the app from the device,
      then run the app from Xcode.  Test on iOS 7,8,9,10,11 and make sure there are no race
      conditions and that the initialization does not deadlock.
  * Removed vestigial CoreTelephony references (GH-#689).
  * Updated project for Xcode 9 compatibility.
  * Update the BranchShareLink.shareURL member field correctly after share event (#696).
  * Added ability to turn logging on and off via links / Info.plist (GH-#697).

- v0.17.10
  * _*Master Release*_ - August 23, 2017
  * Don't do cookie based matching in iOS 11 (AIS-307, GH-#681).
  * Fix an initialization problem in iOS 8.
    Logging was calling a protocol method which would lock up initialization on iOS 8 (GH-#694).

- v0.17.9
  * _*Master Release*_ - August 15, 2017
  * Fixed the Branch.framework static library build. How long was this broken? A year? Since 12.2?
    Good grief.

- v0.17.7
  * _*Master Release*_ - August 14, 2017
  * Fixed some header inclusion and the framework upload.

- v0.17.6
  * _*Master Release*_ - August 11, 2017
  * Added a check for buffer length before reading a pointer.

- v0.17.5
  * _*Master Release*_ - August 8, 2017
  * Fixed Carthage build.

- v0.17.3
  * _*Master Release*_ - August 8, 2017

- v0.17.2
  * _*Beta Release*_ - August 4, 2017
  * Support de-duping our NSUserActivity-based indexed Spotlight search items (With caveats. See
    GitHub PR #668).
  * Added a guard to prevent a crash bug from when bad data was accidentally passed back from the
    Branch servers (GitHub #672).
  * Fixed a crash bug that sometimes occurred when logging to the Branch log file (GitHub #661).
  * Added 'com.googleusercontent.apps' as an o-auth scheme (GitHub #678).
  * Used address sanitizer & thread sanitizer to find and fix several thread and memory errors.
  * Escape extra html tags in dynamic Branch links (INTENG-3466).

- v0.17.1
  * _*Beta Release*_ - August 1, 2017
  * Added support for using a provided network stack instead of the standard Branch SDK network calls.
    See the documentation in the `BNCNetworkServiceProtocol.h` file for details.
  * Added certificate pining for branch.io server calls.
  * Removed support for iOS 6 networking.
  * The iOS Security.framework is now required for linking with the Branch SDK.
  * Cleaned up NSError error messages.
  * Added support for localization of error messages. Send us your localizations!
  * Added Russian translation of user facing SDK messages and errors.

- v0.17.0
  * _*Beta Release*_ - July 24, 2017
  * Added Crashlytics reporting enhancements (#653)
    - The Branch SDK version number is now recorded in Crashlytics logs.
    - The Branch deviceFingerprintId is also recorded in Crashlytics by default. This is optional.
    - Added BNCCrashlyticsWrapper.
    - Added and updated unit tests.
  * BNCDeviceInfo thread safety to prevent crash during initialization (GitHub #654 & #656).
    - Updated all instance properties on BNCDeviceInfo to be totally thread-safe.
    - Made all BNCDeviceInfo properties readonly. Lazy initialization of vendorId due to idiosyncrasy
      of UIDevice.identifierForVendor.
    - Separated messages to deviceInfo from messages to self in a troublesome stack frame.

- v0.16.2
  * *Master Release* - July 13, 2017
  * Decoupled logic for determining app language and app country code.
  * Updated the project for Xcode 9 beta and iOS 11 beta.
  * Removed the dependency on the CoreTelephony framework.
  * Fixed an occasional crash when retrieving country code and language.
  * Made SafariServices an optional CocoaPod podspec.

- v0.16.1
  * *QA Release* - July 5, 2017
  * Added a new method to the API for registering a deep link controller. The API adds presentation
    options for showing the deep link controller:
```
        - (void)registerDeepLinkController:(UIViewController <BranchDeepLinkingController> *)controller
                                    forKey:(NSString *)key
                          withPresentation:(BNCViewControllerPresentationOption)option;
```

    and depreciated the old API:

```
        - (void)registerDeepLinkController:(UIViewController <BranchDeepLinkingController> *)
                controller forKey:(NSString *)key;

```

    See [Registering a view controller to handle deep linking" in the documentation.](https://dev.branch.io/getting-started/deep-link-routing/advanced/ios/#register-view-controller-for-deep-link-routing)

  * Added a WebViewExample-Test schema to illustrate how to use custom configurations and schemas
    to select the Branch environment.
  * Make it easier to use the Branch test key.
    - Added the Branch class methods `useTestBranchKey` and `branchKey` to set the Branch key to use.
    - If `useTestBranchKey` is set to true, Branch will attempt to use the `test` key from the
      Info.plist.
   * Updated the docs to show BranchShareLink usage, especially how the use the BranchShareLink
     delegate to change the share text based on user selection.

- v0.16.0
  * *QA Release* - June 14, 2017
  * Branch support for opening Branch links inside an app once a session is already started (like AppBoy) (AIS-264).
  * Updated logging. Logging is more robust and consistant. Fixed the punctuation and grammer for logging messages.
  * Added a standard `BNCCurrency` type for commerce events.
  * Stop sending the Apple search ad data after attribution has been found or 30 days (AIS-267).
  * Added a deprecation warning added for older BranchActivityItems in BranchUniversalObject.h (#631).

- v0.15.3
  * *Master Release*

- v0.15.2
  * *QA Release*
  * Updated BNCStrongMatchHelper to handle UISplitViewController (#625).

- v0.15.1
  * *Beta Release*
  * Master release candidate.
  * Added an example of opening a Branch link in-app. (#621)

- v0.15.0
  * *Beta Release*
  * Added 'The Planets' WebView example.
    - This example demonstrates how to use Branch links in an app that has table view and web view.
  * Added unit tests and fixed bugs as needed.
    - Changed the NSTimer to a dispatch_timer.  NSTimers only fire in certain run modes.
    - Added environment parameters to control the test cases without re-compiling.
    - Standardized test cases.
    - All tests pass.
  * Updated README.md SDK integration documentation to include the new
    `[Branch application:openURL:sourceApplication:annotation:annotation]` method.
  * Added Email HTML support to BranchActivityItemProvider.
  * Added logging functions for Swift.

- v0.14.12
  * Fixed headers for Swift compatibility AIS-242 (#615).

- v0.14.11
  * *Master Release*
  * Added `BranchShareLink.h` to public headers.

- v0.14.10
  * *Master Release*
  * Fixed a crash bug in `[BNCSystemObserver appBuildDate]`.
  * Added a date in the sharing text for the testbed apps (AIS-228).

- v0.14.9
  * *Master Release*
  * Updated the Branch-TestBed Branch-TestBed-Swift examples.
  * Verified Xcode 8.3 and iOS 10.3 compatibility.

- v0.14.5
  * *Beta Release*
  * Added two new Branch methods for handling opening scheme-based URLs from an app delegate.
    These methods match the corresponding UIApplicationDelegate methods and allow the Branch SDK
    more flexibility when handling scheme-based URLs.  The methods are:

```
        - (BOOL)application:(UIApplication *)application
                    openURL:(NSURL *)url
          sourceApplication:(NSString *)sourceApplication
                 annotation:(id)annotation;
```
    and
```
        - (BOOL)application:(UIApplication *)application
                    openURL:(NSURL *)url
                    options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;
```

- v0.14.4
  * *Beta Release*
  * Fixed `getUpdateState` so it works on enterprise distribution. INTENG-3189 (#601)
  * Added light-weight logging. AIS-193 (#591)

- v0.14.1
  * *Beta Release*
  * Added a new Branch class, `BranchShareLink`, that encapsulates a `BranchUniversalObject`,
    `BranchLinkProperties`, and sharing interaction for easier and more flexible Branch link
    sharing. The class can provide `UIActivityItemProvider` items or present an Apple Activity View
    Controller.
  * Added an example of sharing with the `BranchShareLink` in the Testbed-Swift example app.
  * Added a new BranchUniversalObject method `[BranchUniversalObject userCompletedAction:withState:]`.
  * Minor bug fixes and unit test updates.
  * Updated `transaction_id` for commerce events.
  * Fixed a crash bug when adding Branch identity to Fabric answers.

- v0.13.5
  * Updated Xcode 7 example project to work on iOS 7.
  * Added iAd framework to Swift example so that the Apple Search Ad query works.

- v0.13.1
  * *Beta Release*
  * Version strings are now displayed in the testbed apps.
  * Made sure that Branch callbacks happen on the main thread.
  * Fixed the Xcode 7 example to work with unit tests.
  * Fixed content discovery to work consistently.
  * Updated the Apple Search Ad debug mode campaign name to 'DebugAppleSearchAdsCampaignName'.

- v0.13.0
  * *Beta Release*
  * All the unit tests now compile, run, and pass.
  * Added the `branchAPIURL` property to `BNCPreferenceHelper` instances.
      This property can be set when testing with mocking frameworks like WireMock, where canned
      server responses are needed for functional testing scenarios.

      This property can be set before Branch is initialized.  For example:
      ```objc
      [BNCPreferenceHelper preferenceHelper].branchAPIURL = @"http://localhost/branch-mock";
      [[Branch getInstance] initSessionWithLaunchOptions:launchOptions];
      ```

      Be sure to use the Branch production API URL in production apps!

- v0.12.30
  * Fixed some rare app crashes in BranchOpenRequest due to a race condition.
  * Prevent a crash by making a deep copy of dictionary before merging entries. (#573)
  * Removed NSLog statements added for debugging. (#572)
  * Content Discovery Updates (#571)
    - Adding referred link from response.
      Adding referred link from response in case available.
      Support non-app links click with content discovery.
    - Fixed unnecessary "-" char appended to the CD keys.
    - Fixed a race condition that caused a rare app crash.

- v0.12.29
  * *Beta Release*
  * The browser user agent string is now cached for faster SDK startup (AIS-197).

- v0.12.28
  * *Beta Release*
  * Added the `getLatestReferringParamsSynchronous` method AIS-8 (#536).
    - For details see [`getLatestReferringParamsSynchronous`](https://github.com/BranchMetrics/ios-branch-deep-linking#retrieve-session-install-or-open-parameters)
      in the README.md documentation.
  * Improved the SDK responsiveness when getting the browserUserAgentString.

- v0.12.27
  * Fixed a bug were Facebook and Apple Search Ad attribution weren't checked correctly.
    Facebook would get checked first, and Apple Search Ads wouldn't get checked (INTENG-3137).
  * Fixed a bug were Apple Search Ad attribution would get stuck on (INTENG-3133).
  * Suppressed some compiler deprecation warnings.
  * Removed CocoaPods from the Swift TestBed example since it needlessly complicated building the
    example (AIS-188).

- v0.12.26
  * Updated project and include files for Xcode 8.3.

- v0.12.25
  * *Beta Release*
  * Added a deployment script for beta releases.
  * Fixed crashes related to nil values being inserted into a dictionary (GH #551 & #552).
  * Made callback block properties atomic/copy to prevent a possible crashes due to race conditions.
  * In the BNCServerInterface code, the code blocks for NSURLSessionCompletionHandler and
    NSURLConnectionCompletionHandler are now copied blocks rather global static blocks.
    This prevents a crash when the block is deallocated or reallocated (GH #548).
  * Added a Swift example for the new Branch commerce event, `BNCCommerceEvent`, in the
    TestBed-Swift project.

- v0.12.24
  * Updated Fabric files.
  * Made the release script more robust.
  * Made changes to the Safari Strong Match Helper to ensure that:
    - Safari doesn't steal the firstResponder status.
    - The hidden Safari view is inserted correctly into the ViewController / View hierarchy.

- v0.12.23
  * Updated the public headers for Carthage to include BNCCommerceEvent.h.

- v0.12.22
  * Fixed a crash when the root view controller is UINavigationController during strong matching (#539).
  * Updated documentation.
  * Warn when a user purchase event conflicts with a commerce event DANA-77 (#538).
  * Added product categories DANA-75 (#537).
  * Fixed a potential initialization race condition (#535).
  * Updated the Branch-TestBed-Swift example.
  * Fixed problem where getLatestReferringParams was sometimes returning the wrong params (#532).

- v0.12.21
  * *Beta Release*
  * Fixed iOS 10.2.2 app install/update reporting (INFRA-1484).
  * Don't add 'type' or 'duration' to link data if they're 0 (AIS-97).
  * Made UIApplication use optional so that iMessage extensions could build (GH-#521).
  * Return faster from the Branch initialization call (GH-#520).
    - Cached the browserUserAgentString in BNCDeviceInfo.
    - Made post requests start asynchronously.
  * Changed SDK_VERSION to BNC_SDK_VERSION (GH-#523).
  * Added a 'commerce' event for tracking in-app purchases (DANA-39).
    - Added BNCCommerceEvent.
    - Added test methods for BNCCommerceEvent use.

- v0.12.20
  * Started the SDK beta program. A beta version of the SDK is now available.
    - See the Github info here: https://branch.app.link/5HMUVrQeYy
  * Updated the build script.
  * Merge pull request #517 from brianmichel/bsm/call-javascript-from-main-thread.
  * Fixed and re-applied patches from v0.12.18. These are:
    - Updated share channel names for some older iOS app versions.
    - Updated how the SFSafariViewController window is handled when finding a strong match.
      * The keyWindow and firstResponder will no longer lose focus at app start up (#484, AIS-122).
      * Branch now plays nicely with the Facebook login controller (AIS-122).
    - Improved handling of queued link opens. (#491, #503, AIS-128)
    - Made the preference helper more robust to prevent crashes (#514)
    - Updated nullability of callback parameters for Swift (#509, #507, AIS-149).
    - Fixed some nil reference errors found by static analysis.
    - Fixed a small memory leak.

- v0.12.19
  * Reverted changes from release 0.12.18.

- v0.12.18
  * Updated share channel names for some older iOS app versions.
  * Updated how the SFSafariViewController window is handled when finding a strong match.
    - The keyWindow and firstResponder will no longer lose focus at app start up (#484, AIS-122).
    - Branch now plays nicely with the Facebook login controller (AIS-122).
  * Improved handling of queued link opens. (#491, #503, AIS-128)
  * Made the preference helper more robust to prevent crashes (#514)
  * Updated nullability of callback parameters for Swift (#509, #507, AIS-149).
  * Fixed some nil reference errors found by static analysis.
  * Fixed a small memory leak.

- v0.12.17
  * Made the preference file creation more robust and fault tolerant.

- v0.12.16
  * Branch can now optionally track Apple Search Ad campaign attribution.
  * Sharing channels have been updated to be human readable and match the Android names.
  * Cleaned up some warnings in the system log.
  * Updated TestBed for running devices that run iOS 7.

- v0.12.15
  * Fixed a potential crash bug: Added a nil checks when moving the preferences file.
  * Check for older versions of the Fabric SDK instead of just crashing (AIS-102).
    - Testing note:  This is a pretty contrived problem that isn't easily testable.
      I stepped through the code with the debugger and it worked.
  * Changed the share activity channel from "com.tinyspeck.chatlyio.share" to "Slack"
    to prevent confusion (AIS-59).

- v0.12.14
  * This release fixes a compile error with Xcode 7.

- v0.12.13
  * AIS-106: Included user_agent in device POST parameters.
  * AIS-109: Included language & country in device POST parameters.
  * INT-2882: Moved Branch support files from Documents directory to Application Support directory.
  * Github #487: Updated documentation to mention that application:willFinishLaunchingWithOptions:
    also has to return YES on app launch.
  * Merged the Swift 3.0 Test-Bed.

- v0.12.12
  * Updated Swift example to Swift 3.0
  * Updated Update README.md Documentation Syntax for Swift
  * Removed an initSession option
  * Fixed instrumentation data property types
  * Stopped sending instrumentation data in GET requests
  * Fixed Spotlight content discovery
  * Fixed crash that sometimes occurred when a user completed a Branch action
  * Added email subject to share action
  * Added 'Notes' to the list of sharing channels

- v0.12.11
  * Support for Carthage sub modules
  * Fix for few swift compatibility issues

- v0.12.10
  * Fix for issue causing initSession hang on cold start from universal link
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
  * add canonical ID and URL to spotlight index
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
  * Fix issue with old requests not fitting the new request format, causing crashes.

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
