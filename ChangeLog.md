Branch iOS SDK change log

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
