# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is the **Branch iOS SDK** for deep linking and attribution. Production code is a single
Objective-C library, `BranchSDK`, shipped for **iOS 12+ and tvOS 12+** via SPM, CocoaPods,
Carthage, and prebuilt XCFrameworks. There is no Swift in the shipped product on this branch —
everything under `Sources/BranchSDK/` is `.h`/`.m`.

> The `4.0.0-beta.0` line is a substantially different architecture (NSOperationQueue-based
> request queue, `/v3` endpoints). Do not apply this file's architecture notes to that branch.

## Products and distribution

One source tree, several delivery vehicles — all built from `Sources/BranchSDK/**/*.{h,m}`:

- **SPM** — `Package.swift`, target `BranchSDK`, `publicHeadersPath: BranchSDK/Public/`,
  private headers reachable only via the `BranchSDK/Private` header search path.
- **CocoaPods** — `BranchSDK.podspec`. tvOS **excludes** `BNCContentDiscoveryManager`,
  `BNCUserAgentCollector`, and `BNCSpotlightService`.
- **XCFramework** — `BranchSDK.xcodeproj` schemes `xcframework`, `xcframework-noidfa`,
  `static-xcframework`, driven by `scripts/build_xcframework*.sh` / `prep_*`.
- **IDFA-free variants** — the `-noidfa` scripts are the _same_ sources compiled with
  `GCC_PREPROCESSOR_DEFINITIONS=BRANCH_EXCLUDE_IDFA_CODE=1`. Any new AdSupport/IDFA touch
  must be guarded by that macro or the no-IDFA build breaks at App Store review time,
  not at compile time.

Version lives in **four** places, all rewritten by `scripts/version.sh`: the `version=` literal in
`scripts/version.sh` itself (the value the script reads back, so effectively the source of truth),
`BNC_SDK_VERSION` in `Sources/BranchSDK/BNCConfig.m`, `s.version` in `BranchSDK.podspec`, and
`MARKETING_VERSION` in `BranchSDK.xcodeproj/project.pbxproj` (6 build configurations). All four
currently agree at `3.14.2`. Never hand-edit any of them.

```bash
./scripts/version.sh        # print current version
./scripts/version.sh -i     # increment patch and update all four
./scripts/version.sh -u     # update the files to the current version, no increment
```

Do **not** reach for `bundle exec fastlane version_bump` or the `version-bump.yml` workflow:
`fastlane/lib/helper/version_helper.rb` still patches `carthage-files/`, `Branch-SDK/BNCConfig.m`,
`Branch.podspec` and `Branch-TestBed/Framework-Info.plist` — none of which exist on this branch.

## Source layout

Everything is flat under `Sources/BranchSDK/`, with headers split by visibility:

- **`Sources/BranchSDK/*.m`** — all implementations (72 files).
- **`Sources/BranchSDK/Public/`** — the public header surface. Adding a header here is a
  **public API change**; adding one to `Private/` is not.
- **`Sources/BranchSDK/Private/`** — internal headers (`BNCServerAPI.h`, `BNCRequestFactory.h`,
  `BNCPreferenceHelper` internals, request subclasses, …).
- **`Sources/Resources/`** — `PrivacyInfo.xcprivacy` (the privacy manifest), umbrella header,
  modulemap.

Naming convention is load-bearing: `BNC*` = internal/support type, `Branch*` = public-facing
type or a server request. `BNCServerRequest` subclasses are all named `Branch<Thing>Request`.

## Where to make changes

| Task                                                    | Start here                                                                                                                                                                                                                                                                                                                                                              |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Session/init flow, init status, deep-link callbacks     | `Branch.m` — `initUserSessionAndCallCallback:`, `initializeSessionAndCallCallback:`, `handleInitSuccessAndCallCallback:`, `handleInitFailure:`                                                                                                                                                                                                                          |
| Universal link / scheme / push / user-activity entry    | `Branch.m` — `handleDeepLink:sceneIdentifier:`, `handleSchemeDeepLink_private:`, `handleUniversalDeepLink_private:`, `continueUserActivity:`, `handlePushNotification:`                                                                                                                                                                                                 |
| UIScene lifecycle entry (scene-based apps)              | `BranchScene.m` — `initSessionWithLaunchOptions:registerDeepLinkHandler:`, `scene:continueUserActivity:`, `scene:openURLContexts:`; each forwards into `Branch.m` (`initSceneSessionWithLaunchOptions:…`, `continueUserActivity:sceneIdentifier:`, `sceneIdentifier:openURL:…`) with the scene `persistentIdentifier`                                                   |
| A new API request type                                  | subclass `BNCServerRequest` (see `BranchOpenRequest.m`, `BranchEventRequest` in `BranchEvent.m`); build its body in `BNCRequestFactory`; add the endpoint to `BNCServerAPI`                                                                                                                                                                                             |
| Request body fields / wire format                       | `BNCRequestFactory.m` (`dataForInstallWithURLString:`, `dataForOpenWithURLString:`, `dataForEventWithEventDictionary:`, `dataForShortURLWithLinkDataDictionary:`, `dataForLATDWithDataDictionary:`)                                                                                                                                                                     |
| Wire key names / response keys                          | `BranchConstants.m` (`BRANCH_REQUEST_KEY_*`, `BRANCH_RESPONSE_KEY_*`)                                                                                                                                                                                                                                                                                                   |
| Endpoint paths / base URL / hosts                       | `BNCServerAPI.m` — paths are string literals on `installServiceURL`, `openServiceURL`, `standardEventServiceURL`, `customEventServiceURL`, `linkServiceURL`, `qrcodeServiceURL`, `latdServiceURL`, `validationServiceURL`; hosts in `BNCConfig.m`. The `BRANCH_REQUEST_ENDPOINT_*` constants in `BranchConstants.m` are dead — 7 definitions, 7 externs, zero consumers |
| Persisted state / a new preference key                  | `BNCPreferenceHelper.m` — add a `BRANCH_PREFS_KEY_*` constant plus a typed accessor                                                                                                                                                                                                                                                                                     |
| Queue behavior, ordering, draining                      | `BNCServerRequestQueue.m` **plus** `Branch.m` `processNextQueueItem` / `processRequest:response:error:` — the queue is a dumb container; the driving loop lives in `Branch.m`                                                                                                                                                                                           |
| HTTP transport, retries, timeouts                       | `BNCServerInterface.m` (`genericHTTPRequest:retryNumber:callback:retryHandler:`), `BNCNetworkService.m`                                                                                                                                                                                                                                                                 |
| Device/hardware signals on requests                     | `BNCDeviceInfo.m`, `BNCSystemObserver.m`, `BNCDeviceSystem.m`, `BNCNetworkInterface.m`                                                                                                                                                                                                                                                                                  |
| Link creation (short/long URLs)                         | `BranchShortUrlRequest.m`, `BranchShortUrlSyncRequest.m`, `BNCLinkData.m`, `BNCLinkCache.m`; content model in `BranchUniversalObject.m`, `BranchLinkProperties.m`                                                                                                                                                                                                       |
| Sharing / share sheet                                   | `BranchShareLink.m`, `BranchActivityItemProvider.m`                                                                                                                                                                                                                                                                                                                     |
| Custom & commerce events                                | `BranchEvent.m` (also defines `BranchEventRequest`), `BNCCurrency.m`, `BNCProductCategory.m`                                                                                                                                                                                                                                                                            |
| Tracking-disabled / consent / attribution level         | `Branch.m` (`setConsumerProtectionAttributionLevel:`, `+setTrackingDisabled:`), `BNCPreferenceHelper.m`                                                                                                                                                                                                                                                                 |
| SKAdNetwork / ATT                                       | `BNCSKAdNetwork.m`, `Branch.m` `handleATTAuthorizationStatus:`                                                                                                                                                                                                                                                                                                          |
| Referring-URL query params (gclid, gbraid, sccid, Meta) | `BNCReferringURLUtility.m`, `BNCUrlQueryParameter.m`                                                                                                                                                                                                                                                                                                                    |
| URL ignore/skip list                                    | `BNCURLFilter.m` (ships a default list, refreshes from the server post-init)                                                                                                                                                                                                                                                                                            |
| `branch.json` / config flags / key source               | `BranchJsonConfig.m`, `BranchConfigurationController.m`, `Branch.m` `+branchKey`                                                                                                                                                                                                                                                                                        |
| Spotlight / content indexing (iOS only)                 | `BNCSpotlightService.m`, `BNCContentDiscoveryManager.m`, `BranchContentDiscoverer.m`                                                                                                                                                                                                                                                                                    |
| QR codes                                                | `BranchQRCode.m`, `BNCQRCodeCache.m`                                                                                                                                                                                                                                                                                                                                    |
| Integration / deep-link diagnostics                     | `Branch+Validator.m`                                                                                                                                                                                                                                                                                                                                                    |
| Logging                                                 | `BranchLogger.m`, `BranchFileLogger.m`                                                                                                                                                                                                                                                                                                                                  |

## Build, test, lint

Toolchain: Ruby 2.7 + Bundler for the fastlane path. Xcode is pinned in exactly one workflow —
`layer1-logger-tests.yml` uses `setup-xcode@v1` with `xcode-version: "16"` on `macos-15`.
`verify.yml` (the PR gate) also runs on `macos-15` but takes the runner image's default Xcode;
every other workflow is `macos-latest` and unpinned, and `gptdriver-release.yml` pins 15.4.
There is no style linter (SwiftLint/OCLint) anywhere, but `release.yml` runs a `static-analysis`
job (`xcodebuild analyze`) that gates the rest of the release, and `scripts/prep_release.sh` runs
`pod lib lint` — code that merely compiles is not necessarily release-clean.

```bash
# The everyday loop — the same thing CI runs (fastlane + Branch-TestBed-CI test plan)
bundle install
bundle exec fastlane unit_tests

# Same tests without fastlane
xcodebuild test \
  -project Branch-TestBed/Branch-TestBed.xcodeproj \
  -scheme Branch-TestBed-CI \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest"

# A single test class
xcodebuild test ... -only-testing:Branch-SDK-Tests/BNCRequestFactoryTests

# Unit + integration (network-touching) tests — manual, not on PRs
bundle exec fastlane integration_tests

# Build the distributable XCFrameworks
xcodebuild -scheme xcframework
xcodebuild -scheme xcframework-noidfa
```

**Test layout on this branch:** tests live under `Branch-TestBed/`, not next to `Sources/`.

- `Branch-TestBed/Branch-SDK-Tests/` — the main suite (~46 files), hosted in the TestBed app.
- `Branch-TestBed/Branch-SDK-Unhosted-Tests/` — the few tests that must run without an app host.
- `Branch-TestBed/Reflection_ODM_Tests/` — ODM reflection tests, own scheme and test plan.
- `Branch-TestBed/TestBed-GPTDriverTests/` — MobileBoost/GPTDriver E2E, test plans `Smoke`,
  `Release`, `L1Validation`.

`Branch-TestBed-CI.xctestplan` is the PR gate's plan, and it runs **only the
`Branch-SDK-Tests` target** — `Reflection_ODM_Tests` is present but `"enabled": false`. If you
add a test target, add it to that plan or CI will never run it.

### CI

- **`verify.yml`** — the PR gate. Runs `fastlane unit_tests` on `macos-15`, uploads results
  and Codecov coverage (`slather` → cobertura).
- **`layer1-logger-tests.yml`** — "Layer 1" wire validation. Builds the TestBed, runs
  `L1WireValidationTest` on an iPhone 16 simulator, captures `branchlogs.txt`, and asserts
  required device/SDK fields are actually on the wire via `scripts/validate_l1_logs.py`.
  Only triggers on changes to `Sources/**`, `Branch-TestBed/**`, or the validator itself.
  Reproduce locally:
  ```bash
  python3 scripts/validate_l1_logs.py path/to/branchlogs.txt
  python3 -m unittest scripts.test_validate_l1_logs -v   # validator self-tests
  ```
  The self-test runs **before** the real validation on purpose: a broken validator would
  otherwise show up as a false PASS.
- **`pre-release-qa.yml` / `post-release-qa.yml`** — exercise every package manager
  (CocoaPods, Carthage, SPM, XCFramework) for iOS and tvOS against `SDKIntegrationTestApps/`.
- **`release.yml`** — builds and signs the XCFrameworks with checksums.
- **`integration-tests.yml`** — manual only (`gh workflow run integration-tests.yml`).

## Architecture

### Singleton wiring (`Branch.m`)

`Branch` is a process singleton reached through `+[Branch getInstance]`. The designated
initializer is `-initWithInterface:queue:cache:preferenceHelper:key:` (~line 198), which wires:

- `serverInterface` — `BNCServerInterface`, the HTTP layer (swappable; tests inject a mock)
- `requestQueue` — `BNCServerRequestQueue` (the shared instance)
- `preferenceHelper` — `BNCPreferenceHelper`, persistent state
- `linkCache` — `BNCLinkCache`, memoizes short-URL responses
- `serverAPI` — `BNCServerAPI`, resolves base URL (prod / EU / SafeTrack / custom)
- `isolationQueue` — a **serial** `dispatch_queue_t` named `branchIsolationQueue`
- `processing_sema` — a `dispatch_semaphore_t(1)` guarding the network-count check

**The isolation queue is the concurrency model.** Nearly every public entry point hops onto
`self.isolationQueue` before touching state, which is what makes ordering deterministic.
Adding a code path that mutates session state _without_ going through that queue is the most
common way to introduce a race here.

**Branch key resolution precedence** (`+[Branch branchKey]`): explicit `setBranchKey:` /
`getInstance:` → `branch.json` via `BranchJsonConfig` → `Info.plist` `branch_key` (dict form
with live/test entries, or a bare string). Keys must be prefixed `key_live_` or `key_test_`;
anything else is rejected with an error. The resolved source is recorded on
`BranchConfigurationController.branchKeySource` and reported to the server.

### Session init flow

Init status is a three-state enum, `BNCInitStatus { Uninitialized, Initializing, Initialized }`,
held on `Branch.initializationStatus`.

1. **Entry** — the app calls one of the many `initSessionWithLaunchOptions:…` overloads (all
   funnel into one implementation), or a link arrives later via `handleDeepLink:`,
   `continueUserActivity:`, or `handlePushNotification:`.
2. **`initUserSessionAndCallCallback:sceneIdentifier:urlString:reset:`** — the single funnel.
   Handles plugin deferral first (see below), then hops to the isolation queue. It runs a full
   init when `reset` is set or status is `Uninitialized`; if already `Initialized` and a
   callback was requested, it just replays the cached params on the main queue.
3. **`initializeSessionAndCallCallback:…`** — fires the `branch:willStartSessionWithURL:`
   delegate call and `BranchWillStartSessionNotification`, then on the isolation queue:
   takes `setWaitNeededForOpenResponseLock`, looks for an in-flight open via
   `findExistingInstallOrOpen`, and either
   - **inserts a new request at index 0** — `BranchInstallRequest` if there is no
     `randomizedBundleToken` yet, otherwise `BranchOpenRequest`; or
   - **inserts a link-resolution open at index 1** when an install/open is already queued and
     a new URL arrived — deliberately _behind_ the one already in flight.

   Then sets status to `Initializing` and calls `processNextQueueItem`.

4. **Response** — the init callback lands on the **main** queue and routes to
   `handleInitSuccessAndCallCallback:` (sets `Initialized`, runs the `_branch_validate` /
   `bnc_validate` / `validate_integration` debug hooks, invokes the app callback, posts the
   open notification, refreshes the URL skip list, optionally auto-deep-links) or
   `handleInitFailure:`.

**`initSafetyCheck`** (SDK-631 workaround): several public methods call it, and if status is
`Uninitialized` it silently kicks off an init rather than returning an error. This means an
app that never calls `initSession` can still emit requests — surprising, and load-bearing for
back-compat. Don't "clean it up".

**Plugin deferral:** when `deferInitForPluginRuntime` is set (via `branch.json`), init blocks
are cached until `notifyNativeToInit` is called. A URL arriving during deferral is stashed in
`cachedURLString` and replayed on the next init; a lifecycle call _without_ a URL is dropped.

**Synchronous referring-params getters** (`getLatestReferringParamsSynchronous`) block on
`[BranchOpenRequest waitForOpenResponseLock]`. Never call them on the main thread.

### The request queue

Two pieces, deliberately split:

- **`BNCServerRequestQueue`** — an in-memory `NSMutableArray` behind `@synchronized (self)`.
  It is a **container only**: `enqueue`, `insert:at:`, `dequeue`, `peek`/`peekAt:`, `remove:`,
  `queueDepth`, `containsInstallOrOpen`, `findExistingInstallOrOpen`. It has no timer, no
  persistence, and no execution logic. **Queued requests do not survive a process restart.**
- **`Branch.m` `processNextQueueItem`** — the driver. Waits on `processing_sema`, and if
  `networkCount == 0 && queueDepth > 0` sets `networkCount = 1`, peeks the head, and dispatches
  `makeRequest:key:callback:` on a global queue. Exactly **one request is in flight at a time**;
  `processRequest:response:error:` resets `networkCount` and re-enters the loop.

**Session gating happens in `processNextQueueItem`, not in the queue.** Before dispatching, a
non-install request with no `randomizedBundleToken` fails with `BNCInitError` ("User session has
not been initialized!"), and a non-open request missing `randomizedDeviceToken` or `sessionID`
fails the same way. Both checks are skipped entirely when tracking is disabled.

**Network-failure handling drains, it does not retry.** On a network error,
`processRequest:response:error:` collects every queued request, removes the ones that are not
replayable, zeroes `networkCount`, and calls every collected request's callback with the error.
`isReplayableRequest:` returns YES for **`BranchEventRequest` only**, and even then only when the
client did **not** register a completion callback (a registered callback means the app owns the
retry). Everything else is dropped on the floor.

HTTP-level retries are separate and live in `BNCServerInterface`: `retryCount` (default 3) and
`retryInterval` (default 0) from `BNCPreferenceHelper`, applied only to retryable status codes.

### `BNCPreferenceHelper` — persistent state

A singleton over a **custom archive file**, not `NSUserDefaults`: the dictionary is serialized
with `NSKeyedArchiver` (secure coding) and written atomically to a file named `BNCPreferences`
on a dedicated `_persistPrefsQueue`. Every write goes through `writeObjectToDefaults:value:`
under `@synchronized (self)`.

Consequences worth knowing before you touch it:

- Anything stored must be **secure-coding compatible** or the whole archive silently fails to
  serialize (caught and logged, not thrown).
- `useStorage == NO` keeps everything in memory (used by tests).
- `+clearAll` deletes the file outright.
- A few values live in the **keychain** instead, via `BNCKeyChain` — `BNCApplication` stores
  first-build and first-install dates there so they survive app reinstall. Those are what make
  install-vs-reinstall attribution work; do not migrate them to the prefs file.

Stores: randomized device/bundle tokens, session ID, identity, session params (latest) vs
install params (first-ever), link-click / spotlight / universal-link / local-URL identifiers,
initial referrer, gclid/gbraid/sccid with their validity windows, ODM info (180-day window),
SKAdNetwork window state, consent/attribution level, tracking state, and network tuning
(timeout 5.5 s, third-party API timeout 0.5 s, retry count 3).

## Non-obvious invariants

- **Ordering is a guarantee.** Init is force-inserted at index 0; a link-resolution open goes to
  index 1 specifically so it lands behind the in-flight init. Reordering or "optimizing" queue
  insertion changes attribution behavior.
- **One in-flight request, enforced by `networkCount` + `processing_sema`, not by the queue.**
  Code that calls `makeRequest:` directly bypasses the whole gate.
- **`getLatestReferringParams` reads `sessionParams`; `getFirstReferringParams` reads
  `installParams`.** Install params are written once, on the first-ever install response.
- **Tracking disabled ≠ attribution level NONE, but setting NONE forces tracking off.**
  `setConsumerProtectionAttributionLevel:BranchAttributionLevelNone` flips
  `trackingDisabled = YES` as a side effect; the levels are `FULL`, `REDUCED`, `MINIMAL`, `NONE`.
- **Categories must be force-loaded, but not by the function that looks like it does it.** Static
  linking strips ObjC categories, so each category exposes a no-op `BNCForce…CategoryToLoad`
  symbol. What actually registers them is `__attribute__((constructor))` on the declaration in the
  private header — present on `NSError+Branch`, `NSString+Branch`, `NSMutableDictionary+Branch`
  and `UIViewController+Branch`, and **not `__attribute__((constructor))`-decorated on
  `Branch+Validator`** (it does define `BNCForceBranchValidatorCategoryToLoad`, but only
  `ForceCategoriesToLoad()` calls it manually — grepping for the symbol will find it and mislead).
  `ForceCategoriesToLoad()` in `Branch.m` aggregates all five calls but has **zero call sites in
  the repo**, so adding a line to it changes nothing. A new category needs the
  `__attribute__((constructor))` form; do not model it on `Branch+Validator`. (Nothing in CI or
  the tests verifies category presence in the static XCFramework, so this is convention, not a
  guarded invariant.)
- **`BNCInitSessionResponse` is built fresh on every callback path** — there are three separate
  construction sites in `Branch.m`. Adding a field means updating all of them.
- **IDFA code must be `BRANCH_EXCLUDE_IDFA_CODE`-guarded** (see Products above).
- **tvOS support is the `#if !TARGET_OS_TV` guard in the source; the podspec exclusion is
  CocoaPods-only.** `Package.swift` and the XCFramework tvOS slice compile _every_ file under
  `Sources/BranchSDK/`, with no exclusions. `BNCContentDiscoveryManager`, `BNCUserAgentCollector`
  and `BNCSpotlightService` are listed in `s.tvos.exclude_files` **and** wrapped in
  `#if !TARGET_OS_TV` — the guard is what makes tvOS build. A new iOS-only API needs the guard;
  the podspec exclusion alone is not enough and will break SPM and XCFramework tvOS builds.
- **`BNCURLFilter` self-updates from the server after a successful init**
  (`updatePatternListFromServerWithCompletion:`), so the skip list at runtime may differ from
  the compiled-in default list. Tests that assert on filtering must pin the pattern list.

## Conventions

- Commit prefix: `EMT-XXXX` (Jira). Branch off and PR into `master`.
- Match the surrounding file's style — this codebase is long-lived Objective-C with
  `@synchronized` blocks and explicit nil checks; keep that idiom rather than importing a newer
  one into one file.
- Public headers under `Public/` are an API contract. Adding, renaming, or changing a signature
  there is a breaking-change review, not a refactor.
- `ChangeLog.md` is maintained by hand, per release. `sync-readme-changelog.yml` does **not** read
  it: on a published GitHub release it pushes the release body to the hosted ReadMe.io page
  `ios-version-history` and announces in Slack. Nothing writes into this repo's `README.md`.
