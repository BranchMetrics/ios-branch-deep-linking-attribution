Branch iOS SDK change log

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
