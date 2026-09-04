# Architecture (master, 3.x)

## Singleton wiring

`Branch` is a process singleton reached through `+[Branch getInstance]`. The designated
initializer is `-initWithInterface:queue:cache:preferenceHelper:key:` in `Branch.m`, which
wires `serverInterface` (`BNCServerInterface`, swappable so tests can inject a mock),
`requestQueue` (`BNCServerRequestQueue`), `preferenceHelper`, `linkCache` (`BNCLinkCache`,
memoizes short-URL responses), `serverAPI` (resolves prod / EU / SafeTrack / custom base URL),
`isolationQueue` (a serial `dispatch_queue_t` named `branchIsolationQueue`), and
`processing_sema`, a `dispatch_semaphore_t(1)` guarding the network-count check.

**The isolation queue is the concurrency model.** Nearly every public entry point hops onto
`self.isolationQueue` before touching state, which is what makes ordering deterministic.
Adding a path that mutates session state without going through it is the most common way to
introduce a race here.

**Branch key precedence** in `+[Branch branchKey]`: explicit `setBranchKey:` or `getInstance:`,
then `branch.json` via `BranchJsonConfig`, then the `Info.plist` `branch_key` entry (dict form
with live/test keys, or a bare string). Keys must be prefixed `key_live_` or `key_test_`;
anything else is rejected with an error. The resolved source is recorded on
`BranchConfigurationController.branchKeySource` and reported to the server.

## Session init flow

Init status is a three-state enum, `BNCInitStatus { Uninitialized, Initializing, Initialized }`,
held on `Branch.initializationStatus`.

1. **Entry.** The app calls one of the `initSessionWithLaunchOptions:…` overloads (all funnel
   into one implementation), or a link arrives later via `handleDeepLink:`,
   `continueUserActivity:`, or `handlePushNotification:`.
2. **`initUserSessionAndCallCallback:sceneIdentifier:urlString:reset:`** is the single funnel.
   It handles plugin deferral first, then hops to the isolation queue. It runs a full init when
   `reset` is set or status is `Uninitialized`; if already `Initialized` and a callback was
   requested it just replays the cached params on the main queue.
3. **`initializeSessionAndCallCallback:…`** fires the `branch:willStartSessionWithURL:` delegate
   call and `BranchWillStartSessionNotification`, then on the isolation queue takes
   `setWaitNeededForOpenResponseLock`, looks for an in-flight open via
   `findExistingInstallOrOpen`, and either inserts a new request at index 0
   (`BranchInstallRequest` when there is no `randomizedBundleToken` yet, otherwise
   `BranchOpenRequest`), or inserts a link-resolution open at index 1 when an install/open is
   already queued and a new URL arrived, deliberately behind the one in flight. Then it sets
   status to `Initializing` and calls `processNextQueueItem`.
4. **Response** lands on the main queue and routes to `handleInitSuccessAndCallCallback:` (sets
   `Initialized`, runs the `_branch_validate` / `bnc_validate` / `validate_integration` debug
   hooks, invokes the app callback, posts the open notification, refreshes the URL skip list,
   optionally auto-deep-links) or to `handleInitFailure:`.

**`initSafetyCheck`** (the SDK-631 workaround) is called by several public methods, and if
status is `Uninitialized` it silently kicks off an init rather than returning an error. An app
that never calls `initSession` can therefore still emit requests. Surprising, and load-bearing
for backward compatibility. Do not clean it up.

**Plugin deferral.** When `deferInitForPluginRuntime` is set via `branch.json`, init blocks are
cached until `notifyNativeToInit` is called. A URL arriving during deferral is stashed in
`cachedURLString` and replayed on the next init; a lifecycle call without a URL is dropped.

**Synchronous referring-params getters** (`getLatestReferringParamsSynchronous`) block on
`[BranchOpenRequest waitForOpenResponseLock]`. Never call them on the main thread.

## The request queue

Two pieces, deliberately split.

**`BNCServerRequestQueue`** is an in-memory `NSMutableArray` behind `@synchronized (self)`, and
a container only: `enqueue`, `insert:at:`, `dequeue`, `peek`/`peekAt:`, `remove:`, `queueDepth`,
`containsInstallOrOpen`, `findExistingInstallOrOpen`. No timer, no persistence, no execution
logic. Queued requests do not survive a process restart.

**`Branch.m` `processNextQueueItem`** is the driver. It waits on `processing_sema`, and if
`networkCount == 0 && queueDepth > 0` sets `networkCount = 1`, peeks the head, and dispatches
`makeRequest:key:callback:` on a global queue. Exactly one request is in flight at a time;
`processRequest:response:error:` resets `networkCount` and re-enters the loop. Code that calls
`makeRequest:` directly bypasses the whole gate.

**Session gating happens in `processNextQueueItem`, not in the queue.** Before dispatching, a
non-install request with no `randomizedBundleToken` fails with `BNCInitError` ("User session has
not been initialized!"), and a non-open request missing `randomizedDeviceToken` or `sessionID`
fails the same way. Both checks are skipped entirely when tracking is disabled.

**Network failure drains, it does not retry.** `processRequest:response:error:` collects every
queued request, removes the ones that are not replayable, zeroes `networkCount`, and calls every
collected callback with the error. `isReplayableRequest:` returns YES for `BranchEventRequest`
only, and even then only when the client did not register a completion callback (a registered
callback means the app owns the retry). Everything else is dropped.

HTTP-level retries are separate and live in `BNCServerInterface`: `retryCount` (default 3) and
`retryInterval` (default 0) from `BNCPreferenceHelper`, applied only to retryable status codes.

## Persistent state

`BNCPreferenceHelper` is a singleton over a **custom archive file**, not `NSUserDefaults`. The
dictionary is serialized with `NSKeyedArchiver` (secure coding) and written atomically to a file
named `BNCPreferences` on a dedicated `_persistPrefsQueue`. Every write goes through
`writeObjectToDefaults:value:` under `@synchronized (self)`.

- Anything stored must be secure-coding compatible, or the whole archive silently fails to
  serialize. The failure is caught and logged, not thrown.
- `useStorage == NO` keeps everything in memory. Tests use this.
- `+clearAll` deletes the file outright.
- A few values live in the **keychain** via `BNCKeyChain` instead. `BNCApplication` stores
  first-build and first-install dates there so they survive app reinstall. Those are what make
  install-versus-reinstall attribution work. Do not migrate them into the prefs file.

Stored: randomized device/bundle tokens, session ID, identity, session params (latest) versus
install params (first-ever), link-click / spotlight / universal-link / local-URL identifiers,
initial referrer, gclid/gbraid/sccid with their validity windows, ODM info (180-day window),
SKAdNetwork window state, consent and attribution level, tracking state, and network tuning
(timeout 5.5s, third-party API timeout 0.5s, retry count 3).

## Non-obvious invariants

- **Ordering is a guarantee.** Init is force-inserted at index 0; a link-resolution open goes to
  index 1 specifically so it lands behind the in-flight init. Reordering queue insertion changes
  attribution behavior.
- **One in-flight request, enforced by `networkCount` plus `processing_sema`, not by the queue.**
- **`getLatestReferringParams` reads `sessionParams`; `getFirstReferringParams` reads
  `installParams`.** Install params are written once, on the first-ever install response.
- **Tracking disabled is not the same as attribution level NONE, but setting NONE forces
  tracking off.** `setConsumerProtectionAttributionLevel:BranchAttributionLevelNone` flips
  `trackingDisabled = YES` as a side effect. Levels are `FULL`, `REDUCED`, `MINIMAL`, `NONE`.
- **Categories must be force-loaded, but not by the function that looks like it does it.** Static
  linking strips ObjC categories, so each category exposes a no-op `BNCForce…CategoryToLoad`
  symbol. What actually registers them is `__attribute__((constructor))` on the declaration in
  the private header, present on `NSError+Branch`, `NSString+Branch`,
  `NSMutableDictionary+Branch` and `UIViewController+Branch`, and **not** on `Branch+Validator`
  (which defines `BNCForceBranchValidatorCategoryToLoad` but is only called manually by
  `ForceCategoriesToLoad()`, so grepping for the symbol will find it and mislead).
  `ForceCategoriesToLoad()` in `Branch.m` aggregates all five calls but has zero call sites in
  the repo, so adding a line to it changes nothing. A new category needs the
  `__attribute__((constructor))` form. Nothing in CI verifies category presence in the static
  XCFramework, so this is convention, not a guarded invariant.
- **`BNCInitSessionResponse` is built fresh on every callback path.** There are three separate
  construction sites in `Branch.m`; a new field means updating all of them.
- **`BNCURLFilter` self-updates from the server after a successful init**
  (`updatePatternListFromServerWithCompletion:`), so the runtime skip list can differ from the
  compiled-in default. Tests that assert on filtering must pin the pattern list.
