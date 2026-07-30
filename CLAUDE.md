# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is the **Branch iOS SDK**, on the **`4.0.0-beta.*` rewrite line**. Production code is a
single Objective-C library, `BranchSDK`, for **iOS 12+ / tvOS 12+**, shipped via SPM, CocoaPods,
Carthage, and prebuilt XCFrameworks.

> **This branch is not `master`.** The request queue, the session model, the wire endpoints, and
> parts of the public API all differ. Everything below describes _this_ branch. When porting a
> fix from `master`, assume the queue and init code do not translate directly — check first.
>
> Note: nothing here has been renumbered for beta, and the version locations disagree.
> `BNC_SDK_VERSION` and the podspec read `4.0.0-alpha.0`; `scripts/version.sh` reads `4.0.0`;
> `MARKETING_VERSION` in the pbxproj reads `3.12.1`. See "Products and distribution" before
> touching any of them.

## What changed from `master` (3.x)

The four differences that break most assumptions carried over from 3.x:

1. **The queue is an `NSOperationQueue`.** `BNCServerRequestQueue` no longer stores requests in
   an array that `Branch.m` drains. `processNextQueueItem` is gone from `Sources/` entirely — the
   only remaining occurrences are a stale, unimplemented category declaration in
   `BranchSDKTests/BranchEvent.Test.m` and its twin under `Branch-TestBed/`. Each request is
   wrapped in a `BNCServerRequestOperation` and the operation queue executes it.
2. **New `/v3` endpoints for the open flow, and a two-request open.** `openServiceURL` is now
   `/v3/events/open` (was `/v1/open`), and there is a new `deepLinkServiceURL` → `/v3/deeplink`.
   Nothing else moved: installs are still `/v1/install`, events still `/v2/event/{standard,custom}`.
3. **New public deep-link API.** `requestDeepLinkData:callback:` and friends replace driving
   everything through `initSession…`. `initUserSessionAndCallCallback:…` is now marked
   `__attribute__((deprecated))`.
4. **`+setTrackingDisabled:` / `+trackingDisabled` are removed** from the public header _and_
   from `Branch.m`. Attribution gating is entirely `setConsumerProtectionAttributionLevel:`
   plus the new `+attributionLevelNone`. Code that references `Branch.trackingDisabled` will
   not compile here.

## Products and distribution

One source tree, several delivery vehicles — all built from `Sources/BranchSDK/**/*.{h,m}`:

- **SPM** — `Package.swift`, target `BranchSDK`, `path: "Sources/BranchSDK"` with
  `publicHeadersPath: "Public"`; private headers reachable only via `.headerSearchPath("Private")`.
  (Note these are relative to the target `path` here, unlike on `master`.)
- **CocoaPods** — `BranchSDK.podspec`. tvOS **excludes** `BNCContentDiscoveryManager`,
  `BNCUserAgentCollector`, and `BNCSpotlightService`.
- **XCFramework** — `BranchSDK.xcodeproj` schemes `xcframework`, `xcframework-noidfa`,
  `static-xcframework`, driven by `scripts/build_xcframework*.sh` / `prep_*`.
- **IDFA-free variants** — the `-noidfa` scripts compile the _same_ sources with
  `GCC_PREPROCESSOR_DEFINITIONS=BRANCH_EXCLUDE_IDFA_CODE=1`. Any new AdSupport/IDFA touch must
  be guarded by that macro.

Version is **not** in two places and is **not** currently consistent. `scripts/version.sh` holds
the source of truth as a hard-coded `version=` literal (line 33, currently `4.0.0`) and rewrites
four targets: `BNC_SDK_VERSION` in `Sources/BranchSDK/BNCConfig.m`, `s.version` in
`BranchSDK.podspec`, `MARKETING_VERSION` in `BranchSDK.xcodeproj/project.pbxproj`, and its own
literal. Today those hold three different values: `4.0.0-alpha.0` (BNCConfig.m, podspec), `4.0.0`
(version.sh), `3.12.1` (pbxproj).

**Do not run `version.sh -i` or `-u` on this branch.** It would drop the `-alpha.0` suffix from
both source files, and because `prev_version` is read from the script's own stale literal, the
`MARKETING_VERSION` rewrite silently matches nothing — leaving the repo more divergent than it
started. `bundle exec fastlane version_bump` is not an alternative here either; see CI below.

## Source layout

Flat under `Sources/BranchSDK/`, headers split by visibility:

- **`Sources/BranchSDK/*.m`** — all implementations (75 files).
- **`Sources/BranchSDK/Public/`** — public API surface. Adding a header here is a public API
  change; adding one to `Private/` is not.
- **`Sources/BranchSDK/Private/`** — internal headers, including this branch's new
  `BNCServerRequestOperation.h`, `BranchRequestOpen.h`, `BranchRequestDeepLink.h`.
- **`Sources/Resources/`** — `PrivacyInfo.xcprivacy`, umbrella header, modulemap.

Naming: `BNC*` = internal/support type, `Branch*` = public-facing type or a server request.
Note the deliberately confusable pair on this branch — **`BranchOpenRequest` (legacy, 3.x-style)
and `BranchRequestOpen` (new, `/v3`) are different classes** and both are live. Same for
`BranchRequestDeepLink`, which has no 3.x counterpart. Read the name carefully.

## Where to make changes

| Task                                                    | Start here                                                                                                                                                                                                                                                                       |
| ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The new deep-link resolution flow                       | `Branch.m` — `requestDeepLinkData:callback:`, `requestDeepLinkDataWithLaunchOptions:callback:`, `requestDeepLinkDataWithSceneOptions:scene:callback:`; request in `BranchRequestDeepLink.m`                                                                                      |
| The new attribution open                                | `Branch.m` — `sendOpen`, `sendOpen:skipCallback:`; request in `BranchRequestOpen.m`                                                                                                                                                                                              |
| Queue behavior, ordering, dependencies, cancellation    | `BNCServerRequestQueue.m` **and** `BNCServerRequestOperation.m` — execution now lives in the operation, not in `Branch.m`                                                                                                                                                        |
| Legacy session init (still present, deprecated)         | `Branch.m` — `initUserSessionAndCallCallback:`, `initializeSessionAndCallCallback:`, `handleInitSuccessAndCallCallback:`, `handleInitFailure:`                                                                                                                                   |
| Universal link / scheme / push / user-activity entry    | `Branch.m` — `handleDeepLink:sceneIdentifier:`, `handleSchemeDeepLink_private:`, `handleUniversalDeepLink_private:`, `continueUserActivity:`, `handlePushNotification:`                                                                                                          |
| A new API request type                                  | subclass `BNCServerRequest`; build its body in `BNCRequestFactory`; add the endpoint to `BNCServerAPI`; enqueue via `[self.requestQueue enqueue:req withPriority:]`                                                                                                              |
| Request body fields / wire format                       | `BNCRequestFactory.m` — `dataForInstallWithURLString:`, `dataForOpenWithURLString:`, **`dataForDeepLinkWithURLString:`**, **`dataForRequestOpenWithURLString:`**, `dataForEventWithEventDictionary:`, `dataForShortURLWithLinkDataDictionary:`, `dataForLATDWithDataDictionary:` |
| Endpoints / base URL                                    | `BNCServerAPI.m` (`installServiceURL`, `openServiceURL`, `deepLinkServiceURL`, …), `BNCConfig.m` (hosts)                                                                                                                                                                         |
| Wire key names / response keys                          | `BranchConstants.m` (`BRANCH_REQUEST_ENDPOINT_*`, `BRANCH_RESPONSE_KEY_*`)                                                                                                                                                                                                       |
| Persisted state / a new preference key                  | `BNCPreferenceHelper.m` — add a `BRANCH_PREFS_KEY_*` constant plus a typed accessor                                                                                                                                                                                              |
| HTTP transport, retries, timeouts                       | `BNCServerInterface.m` (`genericHTTPRequest:retryNumber:callback:retryHandler:`), `BNCNetworkService.m`                                                                                                                                                                          |
| Device/hardware signals on requests                     | `BNCDeviceInfo.m`, `BNCSystemObserver.m`, `BNCDeviceSystem.m`, `BNCNetworkInterface.m`                                                                                                                                                                                           |
| Link creation (short/long URLs)                         | `BranchShortUrlRequest.m`, `BranchShortUrlSyncRequest.m`, `BNCLinkData.m`, `BNCLinkCache.m`; content model in `BranchUniversalObject.m`, `BranchLinkProperties.m`                                                                                                                |
| Custom & commerce events                                | `BranchEvent.m` (also defines `BranchEventRequest`), `BNCCurrency.m`, `BNCProductCategory.m`                                                                                                                                                                                     |
| Consent / attribution level                             | `Branch.m` — `setConsumerProtectionAttributionLevel:`, `setConsumerProtectionAttributionLevel:resetSession:`, `+attributionLevelNone`                                                                                                                                            |
| SKAdNetwork / ATT                                       | `BNCSKAdNetwork.m`, `Branch.m` `handleATTAuthorizationStatus:`                                                                                                                                                                                                                   |
| Scene-based lifecycle                                   | `BranchScene.m`, plus `requestDeepLinkDataWithSceneOptions:scene:callback:` in `Branch.m`                                                                                                                                                                                        |
| Referring-URL query params (gclid, gbraid, sccid, Meta) | `BNCReferringURLUtility.m`, `BNCUrlQueryParameter.m`                                                                                                                                                                                                                             |
| URL ignore/skip list                                    | `BNCURLFilter.m`                                                                                                                                                                                                                                                                 |
| `branch.json` / config flags / key source               | `BranchJsonConfig.m`, `BranchConfigurationController.m`, `Branch.m` `+branchKey`                                                                                                                                                                                                 |
| Logging                                                 | `BranchLogger.m`, `BranchFileLogger.m`                                                                                                                                                                                                                                           |

## Build, test, lint

Toolchain: **Xcode 16**, `macos-15` in CI. There is no lint step.

**Tests do not go through fastlane on this branch.** They live in a first-class `BranchSDKTests/`
target inside `BranchSDK.xcodeproj` (~42 files), not under `Branch-TestBed/`:

```bash
# The everyday loop — exactly what CI runs
./scripts/getSimulator
xcodebuild test \
  -project BranchSDK.xcodeproj \
  -scheme BranchSDKTests \
  -destination "platform=iOS Simulator,name=$(cat ./iphoneSim),OS=latest" \
  -testPlan BranchSDKTests

# A single test class
xcodebuild test ... -only-testing:BranchSDKTests/BNCRequestFactoryTests

# Build the distributable XCFrameworks
xcodebuild -scheme xcframework
xcodebuild -scheme xcframework-noidfa
```

`Branch-TestBed/` still exists with the older `Branch-SDK-Tests` target and the fastlane test
plans, but `verify.yml` on this branch does not use them. Adding a test to
`Branch-TestBed/Branch-SDK-Tests/` here means **CI will not run it** — put new unit tests in
`BranchSDKTests/`.

### CI

Ten workflows exist; several are inherited from `master` and **cannot run on this branch**.

- **`verify.yml`** — the only working gate: `xcodebuild test -scheme BranchSDKTests -testPlan BranchSDKTests`.
- **`pre-release-qa.yml` / `post-release-qa.yml`** — exercise every package manager (CocoaPods,
  Carthage, SPM, XCFramework) for iOS and tvOS against `SDKIntegrationTestApps/`.
- **Broken here — fastlane was deleted on this line.** There is no `fastlane/` directory and no
  `Gemfile` (both still exist on `master`), yet `version-bump.yml`, `integration-tests.yml` and
  `release.yml` all shell out to `bundle exec fastlane` after a `bundle check || bundle install`.
  Treat **release, version-bump and integration-tests as non-functional** on this branch until
  fastlane is restored or they are ported.
- **Not present on this branch:** `layer1-logger-tests.yml` (the L1 wire-validation gate) and
  `gptdriver-release.yml`. Both exist on `master`. There is no automated wire-field assertion
  here — wire-format changes are reviewed by hand.

## Architecture

### Singleton wiring (`Branch.m`)

`Branch` is a process singleton reached through `+[Branch getInstance]`. The designated
initializer `-initWithInterface:queue:cache:preferenceHelper:key:` wires `serverInterface`,
`requestQueue`, `preferenceHelper`, `linkCache`, `serverAPI`, a **serial** `isolationQueue`
(`branchIsolationQueue`), and `processing_sema`.

**New on this branch:** the singleton also calls

```objc
[self.requestQueue configureWithServerInterface:_serverInterface
                                      branchKey:key
                               preferenceHelper:preferenceHelper];
```

The queue now needs the interface, key, and preference helper because **it**, not `Branch.m`,
constructs the operations that perform requests. A queue that was never configured will produce
operations with a nil server interface.

`processing_sema` and `networkCount` still exist on `Branch` but no longer gate request
execution — `NSOperationQueue.maxConcurrentOperationCount` does. Treat them as vestigial.

**Branch key resolution precedence** (`+[Branch branchKey]`): explicit `setBranchKey:` /
`getInstance:` → `branch.json` via `BranchJsonConfig` → `Info.plist` `branch_key`. Keys must be
prefixed `key_live_` or `key_test_`. The resolved source is recorded on
`BranchConfigurationController.branchKeySource`.

### The request queue: `NSOperationQueue` + `BNCServerRequestOperation`

**`BNCServerRequestQueue`** owns an `NSOperationQueue` with
`maxConcurrentOperationCount = 1` (named `com.branch.sdk.serverRequestQueue`) — still serial, but
serialized by the OS rather than by a hand-rolled semaphore loop. Its API is now
`enqueue:`, `enqueue:withPriority:`, `clearQueue`, `cancelPendingDeepLinkRequests`,
`containsInstallOrOpen`, `findExistingInstallOrOpen`, `queueDepth`.

**Ordering is expressed two ways**, and both matter:

- **`NSOperationQueuePriority`** — session-critical requests are enqueued with
  `NSOperationQueuePriorityHigh` (init open/install, `BranchRequestOpen`, `BranchRequestDeepLink`);
  everything else defaults to `Normal`.
- **Operation dependencies** — `addInitDependencyIfNeeded:` records the most recent
  `BranchOpenRequest` operation as `currentInitOperation` and makes every **non-init** operation
  `addDependency:` on it while it is unfinished. It is a `weak` reference, so once the init
  operation finishes and deallocates, later requests are no longer gated.

  **A dependency outranks priority, and "init" here means only `BranchOpenRequest`.** Only
  `BranchOpenRequest` and its subclass `BranchInstallRequest` satisfy that `isKindOfClass:` test.
  `BranchRequestOpen` and `BranchRequestDeepLink` are plain `BNCServerRequest` subclasses, so
  despite being enqueued at `High` they are treated as **non-init** and given a dependency on any
  in-flight legacy init — they wait behind it. Conversely, on a pure `/v3` session nothing ever
  becomes `currentInitOperation`, so the dependency gate never engages at all and ordering rests
  on `maxConcurrentOperationCount = 1` plus priority alone. Note this is the opposite grouping
  from the operation's own session-validation step, which treats all three classes as
  session-establishing.

**`BNCServerRequestOperation`** is a concurrent (`isAsynchronous == YES`) `NSOperation` with
manual `isExecuting`/`isFinished` KVO. Its `start` does, in order:

1. Bail if already cancelled.
2. **Attribution gate** — if `attributionLevel == NONE`, drop the request silently, _except_
   for `BranchRequestDeepLink`, which is always allowed through (deep linking must keep working
   with attribution off).
3. **Session validation** — install requests skip it; `BranchOpenRequest`, `BranchRequestOpen`,
   and `BranchRequestDeepLink` skip it (they are what _establishes_ the session); everything
   else requires `randomizedDeviceToken` **and** `sessionID` **and** `randomizedBundleToken`,
   and fails with `BNCInitError` otherwise.
4. Take the matching response lock (`setWaitNeededFor…ResponseLock`) for whichever open/deeplink
   class this is.
5. `makeRequest:key:callback:`, then process the response **synchronously on the main thread**,
   fire `BNCCallbackMap` completion for `BranchEventRequest`, and finish.

**There is no queue-level retry or replay on this branch.** The 3.x "drain the queue and fail
everything on a network error" path is gone with `processNextQueueItem`. HTTP-level retries
still live in `BNCServerInterface` (`retryCount` default 3, `retryInterval` default 0, retryable
status codes only). Requests are **not** persisted; nothing survives a process restart.

### The `/v3` deep-link flow

This is the flow the branch exists for. `requestDeepLinkData:callback:`:

1. If a non-nil `branchLink` is passed, **cancel pending (not yet executing) deep-link
   operations** via `cancelPendingDeepLinkRequests` — so a cold start that already enqueued a
   nil-URL deferred-deep-link request does not produce a second callback.
2. Enqueue a `BranchRequestDeepLink` at `High` priority → `POST /v3/deeplink` with the body from
   `dataForDeepLinkWithURLString:`.
3. On response, `BranchRequestDeepLink.processResponse:` releases the deep-link lock, then:
   - if the response carries `invoke_features` and the feature triggers a web redirect, it calls
     back into `Branch` `sendOpen:skipCallback:YES` — attribution is still sent, but the app's
     init callback is **not** fired, because the user is leaving for a web link;
   - otherwise it fires the app callback and then calls `sendOpen:skipCallback:NO`.
4. `sendOpen:skipCallback:` reaches the network **only if a referring link was resolved** — either
   the caller passed a `branchLink`, or the response's session data carried `~referring_link`.
   `attemptToSendOpen:` checks this; with no referring link it skips the open entirely and calls
   `clearLinkIdentifiers:` instead. When it does send, it enqueues a `BranchRequestOpen` (High) →
   `POST /v3/events/open`, carrying the resolved `link_data` from step 3.

So an open **that resolved a link** is two network requests: resolve, then attribute. A deferred
deep link that resolves nothing is one request and no attribution call. `sendOpen` (no arguments)
is the public entry for the attribution half alone, used when there is no link to resolve.

`handleUniversalDeepLink_private:` on this branch calls `sendOpen` directly — the old
`initUserSessionAndCallCallback:` call there is commented out. Universal-link opens no longer
run the legacy init path.

**`attributionLevel == NONE` short-circuits `sendOpen:skipCallback:`** and calls
`clearLinkIdentifiers` so the same link identifiers are not reused on a later open.

### Legacy session init (still present)

`initUserSessionAndCallCallback:sceneIdentifier:urlString:reset:` still exists and still works —
it is `deprecated`, not removed, and `continueUserActivity:` still routes through it. It funnels
into `initializeSessionAndCallCallback:` which now **enqueues at `NSOperationQueuePriorityHigh`**
instead of inserting at index 0/1, and no longer calls `processNextQueueItem`. Init status is
still `BNCInitStatus { Uninitialized, Initializing, Initialized }` on `Branch.initializationStatus`.

`sendServerRequest:` changed behavior: on `master` it calls `initSafetyCheck` and silently
self-initializes. **Here it refuses** — if status is `Uninitialized` it logs a warning and
completes the request's callback with `BNCInitError` instead of sending. Callers must initialize
first.

**Synchronous referring-params getters** (`getLatestReferringParamsSynchronous`) now wait on
**three** locks — `BranchOpenRequest`, `BranchRequestDeepLink`, and `BranchRequestOpen`. A new
request class that participates in session establishment needs its own lock added there, or the
synchronous getter will return before that request lands.

### `BNCPreferenceHelper` — persistent state

A singleton over a **custom archive file**, not `NSUserDefaults`: the dictionary is serialized
with `NSKeyedArchiver` (secure coding) and written atomically to a file named `BNCPreferences`
on a dedicated persistence queue. Anything stored must be secure-coding compatible or the whole
archive silently fails to serialize (logged, not thrown). `useStorage == NO` keeps everything in
memory (tests). `+clearAll` deletes the file.

A few values live in the **keychain** instead, via `BNCKeyChain` — `BNCApplication` stores
first-build and first-install dates there so they survive reinstall. That is what makes
install-vs-reinstall attribution work; do not move them into the prefs file.

## Non-obvious invariants

- **`BranchOpenRequest` ≠ `BranchRequestOpen`.** Both exist, both hit `/v3/events/open`, and
  they are wired into different flows. Check which one you are editing.
- **The init dependency is a `weak` reference.** `currentInitOperation` going nil silently
  removes the gate for subsequently enqueued requests. If you need a hard ordering guarantee,
  add an explicit `addDependency:`, don't rely on the init hook.
- **Attribution NONE drops requests inside the operation**, before the network layer — a request
  can be enqueued, "succeed", and never have been sent. Tests asserting "no network call" should
  assert on the interface, not on enqueue.
- **`cancelPendingDeepLinkRequests` only cancels operations that are not executing.** A deep-link
  request already in flight will still deliver its callback.
- **`getLatestReferringParams` reads `sessionParams`; `getFirstReferringParams` reads
  `installParams`.** Install params are written once, on the first-ever install response.
- **Categories must be force-loaded, but not by the function that looks like it does it.** Static
  linking strips ObjC categories, so each category exposes a no-op `BNCForce…CategoryToLoad`
  symbol. What registers them is `__attribute__((constructor))` on the private-header
  declaration — present on `NSError+Branch`, `NSString+Branch`, `NSMutableDictionary+Branch` and
  `UIViewController+Branch`, and **absent on `Branch+Validator`**. `ForceCategoriesToLoad()` in
  `Branch.m` aggregates all five calls but has **zero call sites in the repo**, so adding a line
  to it changes nothing. A new category needs the `__attribute__((constructor))` form; do not
  model it on `Branch+Validator`.
- **`BNCInitSessionResponse` is built at several separate sites** in `Branch.m`. Adding a field
  means updating all of them.
- **IDFA code must be `BRANCH_EXCLUDE_IDFA_CODE`-guarded**; **tvOS excludes three files** in the
  podspec (Spotlight, content discovery, user-agent collection).
- **`BNCURLFilter` self-updates from the server after a successful init**, so the runtime skip
  list can differ from the compiled-in default. Pin the pattern list in tests.

## Conventions

- Commit prefix: `EMT-XXXX` (Jira). PRs target `4.0.0-beta.0` for work on this line — check the
  base branch before opening; the repo default is `master`.
- Match the surrounding file's style: long-lived Objective-C with `@synchronized` blocks and
  explicit nil checks.
- Public headers under `Public/` are an API contract. This branch is already carrying breaking
  changes (removed `setTrackingDisabled:`, deprecated `initUserSessionAndCallCallback:`) — new
  ones need to be deliberate and recorded, not incidental.
- `ChangeLog.md` is maintained by hand, per release. `sync-readme-changelog.yml` is unrelated to
  it: on a published GitHub release it pushes the release body to the hosted ReadMe.io page
  `ios-version-history` and announces in Slack. Nothing automates `ChangeLog.md`.
