# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is the **Branch iOS SDK** on the **`4.0.0-beta.*` rewrite line**. Production code is a single
Objective-C library, `BranchSDK`, for **iOS 12+ / tvOS 12+**, shipped via SPM, CocoaPods, Carthage,
and prebuilt XCFrameworks.

> **This branch is not `master`.** The request queue, the session model, the wire endpoints and
> parts of the public API all differ. When porting a fix from `master`, assume the queue and init
> code do not translate directly — check first.

## What changed from `master` (3.x)

1. **The queue is an `NSOperationQueue`.** `processNextQueueItem` is gone from `Sources/`; each
   request is wrapped in a `BNCServerRequestOperation` that the queue executes.
2. **New `/v3` endpoints for the open flow.** `openServiceURL` → `/v3/events/open` (was `/v1/open`),
   plus a new `deepLinkServiceURL` → `/v3/deeplink`. Installs are still `/v1/install`, events moved to
   `/v3/events/{standard,custom}` (was `/v2/event/{standard,custom}`).
3. **New public deep-link API.** `requestDeepLinkData:callback:` and friends replace driving
   everything through `initSession…`, which is now `__attribute__((deprecated))`.
4. **`+setTrackingDisabled:` / `+trackingDisabled` are removed** from the public header _and_ from
   `Branch.m`. Attribution gating is `setConsumerProtectionAttributionLevel:` plus
   `+attributionLevelNone`. Code referencing `Branch.trackingDisabled` will not compile here.

## In flight

Open PRs that change what is documented below. Until they merge, this file describes the branch as
it is today — check the PR before assuming the new shape exists.

- **#1614** — adds `BranchConfiguration` + `[Branch initialize:config]`, deprecating the public API
  setters. Adds `BranchConfiguration.m` alongside the existing `BranchConfigurationController.m`.
- **#1603** — removes the initialization states (`BNCInitStatus`) and `sessionID`. Both are still
  live here, including the `sessionID` requirement in session validation.
- **#1605** — adds AppDelegate convenience functions wrapping `requestDeepLinkData`, replacing
  direct `continueUserActivity:` / `handlePushNotification:` use. Stacked on #1603.

## Products, distribution, versioning

All vehicles build from `Sources/BranchSDK/**/*.{h,m}`. **SPM** — `Package.swift`, with
`publicHeadersPath`/`headerSearchPath` relative to the target `path`, unlike `master`.
**CocoaPods** — `BranchSDK.podspec`; tvOS **excludes** `BNCContentDiscoveryManager`,
`BNCUserAgentCollector`, `BNCSpotlightService`. **XCFramework** — schemes `xcframework`,
`xcframework-noidfa`, `static-xcframework`; the `-noidfa` variants are the same sources with
`BRANCH_EXCLUDE_IDFA_CODE=1`, so guard any new AdSupport/IDFA touch with that macro.

**Version is inconsistent on this branch and you must not "fix" it with the script.**
`BNC_SDK_VERSION` and the podspec read `4.0.0-alpha.0`, `scripts/version.sh` reads `4.0.0`,
`MARKETING_VERSION` reads `3.12.1`. Running `version.sh -i`/`-u` drops the `-alpha.0` suffix and,
because `prev_version` comes from the script's own stale literal, the `MARKETING_VERSION` rewrite
matches nothing — leaving the repo more divergent. `fastlane version_bump` is not an alternative
either; fastlane was deleted on this line.

## Source layout

Flat under `Sources/BranchSDK/` (75 `.m` files), headers split by visibility: `Public/` is the API
contract, `Private/` is internal (including this branch's `BNCServerRequestOperation.h`,
`BranchRequestOpen.h`, `BranchRequestDeepLink.h`). `Sources/Resources/` holds
`PrivacyInfo.xcprivacy`, the umbrella header and the modulemap. Naming: `BNC*` = internal,
`Branch*` = public-facing type or server request.

## Where to make changes

| Task                                                    | Start here                                                                                                                                                                                                                                                                       |
| ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The new deep-link resolution flow                       | `Branch.m` — `requestDeepLinkData:callback:`, `…WithLaunchOptions:`, `…WithSceneOptions:scene:`; request in `BranchRequestDeepLink.m`                                                                                                                                            |
| The new attribution open                                | `Branch.m` — `sendOpen`, `sendOpen:skipCallback:`; request in `BranchRequestOpen.m`                                                                                                                                                                                              |
| Queue behavior, ordering, cancellation                  | `BNCServerRequestQueue.m` **and** `BNCServerRequestOperation.m` — execution lives in the operation, not `Branch.m`                                                                                                                                                               |
| Legacy session init (deprecated, still live)            | `Branch.m` — `initUserSessionAndCallCallback:`, `initializeSessionAndCallCallback:`, `handleInitSuccessAndCallCallback:`, `handleInitFailure:`                                                                                                                                   |
| Universal link / scheme / push / user-activity entry    | `Branch.m` — `handleDeepLink:sceneIdentifier:`, `handleSchemeDeepLink_private:`, `handleUniversalDeepLink_private:`, `continueUserActivity:`, `handlePushNotification:`                                                                                                          |
| A new API request type                                  | subclass `BNCServerRequest`; body in `BNCRequestFactory`; endpoint in `BNCServerAPI`; enqueue via `[self.requestQueue enqueue:req withPriority:]`                                                                                                                                |
| Request body fields / wire format                       | `BNCRequestFactory.m` — `dataForInstallWithURLString:`, `dataForOpenWithURLString:`, **`dataForDeepLinkWithURLString:`**, **`dataForRequestOpenWithURLString:`**, `dataForEventWithEventDictionary:`, `dataForShortURLWithLinkDataDictionary:`, `dataForLATDWithDataDictionary:` |
| Endpoints / base URL                                    | `BNCServerAPI.m` (`installServiceURL`, `openServiceURL`, `deepLinkServiceURL`, …), hosts in `BNCConfig.m`                                                                                                                                                                        |
| Wire key names / response keys                          | `BranchConstants.m` (`BRANCH_REQUEST_ENDPOINT_*`, `BRANCH_RESPONSE_KEY_*`)                                                                                                                                                                                                       |
| Persisted state / a new preference key                  | `BNCPreferenceHelper.m` — a `BRANCH_PREFS_KEY_*` constant plus a typed accessor                                                                                                                                                                                                  |
| HTTP transport, retries, timeouts                       | `BNCServerInterface.m` (`genericHTTPRequest:retryNumber:callback:retryHandler:`), `BNCNetworkService.m`                                                                                                                                                                          |
| Device/hardware signals                                 | `BNCDeviceInfo.m`, `BNCSystemObserver.m`, `BNCDeviceSystem.m`, `BNCNetworkInterface.m`                                                                                                                                                                                           |
| Link creation (short/long URLs)                         | `BranchShortUrlRequest.m`, `BranchShortUrlSyncRequest.m`, `BNCLinkData.m`, `BNCLinkCache.m`; content model in `BranchUniversalObject.m`, `BranchLinkProperties.m`                                                                                                                |
| Custom & commerce events                                | `BranchEvent.m` (also defines `BranchEventRequest`), `BNCCurrency.m`, `BNCProductCategory.m`                                                                                                                                                                                     |
| Consent / attribution level                             | `Branch.m` — `setConsumerProtectionAttributionLevel:`, `…:resetSession:`, `+attributionLevelNone`                                                                                                                                                                                |
| SKAdNetwork / ATT                                       | `BNCSKAdNetwork.m`, `Branch.m` `handleATTAuthorizationStatus:`                                                                                                                                                                                                                   |
| Scene-based lifecycle                                   | `BranchScene.m`, plus `requestDeepLinkDataWithSceneOptions:scene:callback:`                                                                                                                                                                                                      |
| Referring-URL query params (gclid, gbraid, sccid, Meta) | `BNCReferringURLUtility.m`, `BNCUrlQueryParameter.m`                                                                                                                                                                                                                             |
| URL ignore/skip list                                    | `BNCURLFilter.m`                                                                                                                                                                                                                                                                 |
| `branch.json` / config flags / key source               | `BranchJsonConfig.m`, `BranchConfigurationController.m`, `Branch.m` `+branchKey`                                                                                                                                                                                                 |
| Logging                                                 | `BranchLogger.m`, `BranchFileLogger.m`                                                                                                                                                                                                                                           |

## Build & test

Xcode 16, `macos-15` in CI. No lint step. **Tests do not go through fastlane here** — they live in
a first-class `BranchSDKTests/` target inside `BranchSDK.xcodeproj`, not under `Branch-TestBed/`.

```bash
./scripts/getSimulator
xcodebuild test -project BranchSDK.xcodeproj -scheme BranchSDKTests \
  -destination "platform=iOS Simulator,name=$(cat ./iphoneSim),OS=latest" \
  -testPlan BranchSDKTests
```

A test added to `Branch-TestBed/Branch-SDK-Tests/` **will not run in CI** — put new unit tests in
`BranchSDKTests/`. `verify.yml` is the only working gate. `version-bump.yml`, `integration-tests.yml` and `release.yml`
all shell out to `bundle exec fastlane`, and there is no `fastlane/` or `Gemfile` on this line —
treat them as **non-functional**. `layer1-logger-tests.yml` (the L1 wire gate) is not present here,
so there is no automated wire-field assertion; wire changes are reviewed by hand.

## Architecture

**Singleton.** `+[Branch getInstance]` also calls
`configureWithServerInterface:branchKey:preferenceHelper:` on the queue, because **the queue**, not
`Branch.m`, constructs the operations — an unconfigured queue yields operations with a nil server
interface. `processing_sema` and `networkCount` survive but no longer gate execution
(`maxConcurrentOperationCount` does); treat them as vestigial. Branch key precedence: explicit
`setBranchKey:`/`getInstance:` → `branch.json` → `Info.plist` `branch_key`.

**Queue.** `BNCServerRequestQueue` owns an `NSOperationQueue` with `maxConcurrentOperationCount = 1`
— still serial, but serialized by the OS. Ordering comes from `NSOperationQueuePriority`
(session-critical work enqueued `High`) plus dependencies via `addInitDependencyIfNeeded:`.
**A dependency outranks priority, and "init" means only `BranchOpenRequest`** and its subclass
`BranchInstallRequest`, so `BranchRequestOpen` and `BranchRequestDeepLink` — despite `High` — count
as non-init and wait behind any in-flight legacy init. On a pure `/v3` session nothing becomes
`currentInitOperation`, so the gate never engages at all. This is the opposite grouping from the
operation's session-validation step, which treats all three as session-establishing.

**`BNCServerRequestOperation`** is a concurrent `NSOperation` with manual KVO. Its `start`: bail if
cancelled → attribution gate (drop if `NONE`, except `BranchRequestDeepLink`) → session validation
(installs and the three session-establishing classes skip it; everything else needs
`randomizedDeviceToken` **and** `sessionID` **and** `randomizedBundleToken`, else `BNCInitError`) →
take the response lock → request, then process the response synchronously on the main thread.
**No queue-level retry or replay here** — HTTP retries live in `BNCServerInterface`, and requests
are not persisted.

**The `/v3` deep-link flow** is what this branch exists for. `requestDeepLinkData:callback:` cancels
pending (not executing) deep-link operations when given a non-nil `branchLink`, then enqueues a
`BranchRequestDeepLink` → `POST /v3/deeplink`. On response it either calls `sendOpen:skipCallback:YES`
(web redirect: attribution sent, app callback suppressed) or fires the app callback then
`sendOpen:skipCallback:NO`. That reaches the network **only if a referring link was resolved**;
otherwise it calls `clearLinkIdentifiers:`. So a link-resolving open is two requests — resolve, then
attribute. `handleUniversalDeepLink_private:` calls `sendOpen` directly; the legacy init call there
is commented out.

**`BNCPreferenceHelper`** persists to a **custom `NSKeyedArchiver` file** (`BNCPreferences`), not
`NSUserDefaults` — anything stored must be secure-coding compatible or the whole archive silently
fails to serialize. First-build and first-install dates live in the **keychain** via `BNCKeyChain`
so they survive reinstall, which is what makes install-vs-reinstall attribution work; do not move
them. `sendServerRequest:` **refuses** when status is `Uninitialized` (`master` self-initializes),
and the synchronous referring-params getters wait on **three** locks.

## Non-obvious invariants

- **`BranchOpenRequest` ≠ `BranchRequestOpen`.** Both hit `/v3/events/open`, wired into different
  flows. Check which one you are editing.
- **The init dependency is `weak`.** `currentInitOperation` going nil silently removes the gate. For
  a hard ordering guarantee add an explicit `addDependency:`.
- **Attribution `NONE` drops requests inside the operation**, before the network layer — a request
  can be enqueued, "succeed", and never have been sent. Assert on the interface, not on enqueue.
- **`cancelPendingDeepLinkRequests` only cancels operations that are not executing.** One already in
  flight still delivers its callback.
- **`getLatestReferringParams` reads `sessionParams`; `getFirstReferringParams` reads
  `installParams`**, written once on the first-ever install response.
- **Categories must be force-loaded, but not by the function that looks like it does it.** Static
  linking strips ObjC categories, so each exposes a no-op `BNCForce…CategoryToLoad` symbol. What
  registers them is `__attribute__((constructor))` on the private-header declaration — present on
  `NSError+Branch`, `NSString+Branch`, `NSMutableDictionary+Branch` and `UIViewController+Branch`,
  and **not `__attribute__((constructor))`-decorated on `Branch+Validator`** (it does define
  `BNCForceBranchValidatorCategoryToLoad`, but only `ForceCategoriesToLoad()` calls it manually —
  grepping for the symbol will find it and mislead). `ForceCategoriesToLoad()` itself has **zero
  call sites**, so adding a line to it changes nothing.
- **`BNCInitSessionResponse` is built at several separate sites** in `Branch.m`. A new field means
  updating all of them.
- **`BNCURLFilter` self-updates from the server after init**, so the runtime skip list can differ
  from the compiled-in default. Pin the pattern list in tests.

## Conventions

- Commit prefix `EMT-XXXX` (Jira). PRs on this line target `4.0.0-beta.0` — check the base before
  opening; the repo default is `master`.
- Match the surrounding style: long-lived Objective-C, `@synchronized` blocks, explicit nil checks.
- `Public/` headers are an API contract. This branch already carries breaking changes; new ones
  need to be deliberate and recorded.
- `ChangeLog.md` is maintained by hand. `sync-readme-changelog.yml` does not touch it — on a
  published release it pushes the release body to ReadMe.io and announces in Slack.
