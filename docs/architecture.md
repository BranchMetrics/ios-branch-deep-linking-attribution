# Architecture (4.0.0-beta)

## Singleton wiring

`+[Branch getInstance]` does not exist on this line. `+[Branch initialize:]` creates the
singleton via `getInstanceInternal:`, and the designated initializer calls
`configureWithServerInterface:branchKey:preferenceHelper:` on the queue (`Branch.m:477`),
because **the queue**, not `Branch.m`, constructs the operations. An unconfigured queue yields
operations with a nil server interface. `+[Branch sharedInstance]` reaches the same singleton but
errors if it is called before `initialize:`.

`processing_sema` and `networkCount` survive from the 3.x design but no longer gate execution;
`maxConcurrentOperationCount` does. Treat them as vestigial.

Branch key precedence (`+[Branch branchKey]`, `Branch.m:618`): an explicit `+setBranchKey:`,
then `branch.json` via `BranchJsonConfig`, then the `Info.plist` `branch_key` entry. The
`getInstance:` variant that carries a key on `master` does not exist here.

## The queue

`BNCServerRequestQueue` owns an `NSOperationQueue` with `maxConcurrentOperationCount = 1`. Still
serial, but serialized by the OS rather than by a driving loop in `Branch.m`.

Ordering comes from `NSOperationQueuePriority` (session-critical work is enqueued `High`) plus
dependencies attached by `addInitDependencyIfNeeded:`.

**A dependency outranks priority.** `isInitRequest:` (`BNCServerRequestQueue.m:87`) counts all
three session-establishing classes: `BranchOpenRequest`, `BranchRequestOpen` and
`BranchRequestDeepLink`. `BranchInstallRequest` is a subclass of `BranchOpenRequest`, so the
`isKindOfClass:` check covers it too. An init request becomes `currentInitOperation`; every
non-init request enqueued while that one is live gets an `addDependency:` on it.

This is deliberately **the same enumeration** the operation's session-validation step uses
(`BNCServerRequestOperation.m:119`), and the code says so in a comment. The two agreeing is the
invariant: a queue-side check that recognised only `BranchOpenRequest` would report "no init in
flight" for every 4.0 session, since the other two are siblings rather than subclasses. If you
change one enumeration, change the other, and `BranchDeepLinkQueueDrainTests` is what catches
you.

**The remaining sharp edge is the reference, not the grouping.** `currentInitOperation` is
`weak` (`BNCServerRequestQueue.m:26`), so it can go nil and silently remove the gate from
requests enqueued after that. For a hard ordering guarantee, attach an explicit
`addDependency:`.

## `BNCServerRequestOperation`

A concurrent `NSOperation` with manual `isExecuting`/`isFinished` KVO. Its `-start`:

1. bail if cancelled
2. **attribution gate**: drop if the level is `NONE`, except for `BranchRequestDeepLink`
3. **session validation**: installs and the three session-establishing classes skip it;
   everything else needs `randomizedDeviceToken` **and** `randomizedBundleToken`, or it fails
   immediately with `BNCInitError`
4. take the response lock
5. issue the request, then process the response synchronously on the main thread

**No queue-level retry or replay.** HTTP retries live in `BNCServerInterface`, and requests are
not persisted, so nothing survives a process restart.

## The `/v3` deep-link flow

This is what the branch exists for.

`requestDeepLinkData:callback:` cancels pending (not executing) deep-link operations when given a
non-nil `branchLink`, then enqueues a `BranchRequestDeepLink`, which posts to `/v3/deeplink`.

On response it either calls `sendOpen:skipCallback:YES` (web redirect: attribution is sent, the
app callback is suppressed), or it fires the app callback and then `sendOpen:skipCallback:NO`.
That second call reaches the network **only if a referring link was resolved**; otherwise it
calls `clearLinkIdentifiers:`.

So a link-resolving open is two requests: resolve, then attribute.

`handleUniversalDeepLink_private:` no longer kicks off a session at all. It records
`universalLinkUrl` and `referringURL` and returns `+isBranchLink:`; opening the session is
`+[Branch initialize:]`'s job.

**Opens come from foreground or an explicit call, nothing else.** `automaticOpenEvents` defaults
YES. `sendOpen` is a session start with delegate callbacks, install semantics and SKAdNetwork
effects; do not create one from any other path. Install versus open is decided client-side by
`randomizedBundleToken == nil`, and both post to `/v3/events/open`.

## Persistent state

`BNCPreferenceHelper` persists to a **custom `NSKeyedArchiver` file** (`BNCPreferences`), not
`NSUserDefaults`. Anything stored must be secure-coding compatible or the whole archive silently
fails to serialize.

First-build and first-install dates live in the **keychain** via `BNCKeyChain` so they survive
reinstall, which is what makes install-versus-reinstall attribution work. Do not move them.

`sendServerRequest:` no longer gates on an init status. With `BNCInitStatus` gone it just hops
the isolation queue and enqueues. The synchronous referring-params getters wait on **three**
locks; never call them on the main thread.

## Non-obvious invariants

- **`BranchOpenRequest` is not `BranchRequestOpen`.** Both hit `/v3/events/open`, wired into
  different flows.
- **The init dependency is `weak`.** `currentInitOperation` going nil silently removes the gate.
- **Attribution `NONE` drops requests inside the operation**, before the network layer. A request
  can be enqueued, "succeed", and never have been sent. Assert on the interface, not on enqueue.
- **`cancelPendingDeepLinkRequests` only cancels operations that are not executing.** One already
  in flight still delivers its callback.
- **`getLatestReferringParams` reads `sessionParams`; `getFirstReferringParams` reads
  `installParams`**, written once on the first-ever install response.
- **Categories must be force-loaded, but not by the function that looks like it does it.** Static
  linking strips ObjC categories, so each exposes a no-op `BNCForce…CategoryToLoad` symbol. What
  registers them is `__attribute__((constructor))` on the private-header declaration, present on
  `NSError+Branch`, `NSString+Branch`, `NSMutableDictionary+Branch` and `UIViewController+Branch`,
  and **not** on `Branch+Validator` (which does define `BNCForceBranchValidatorCategoryToLoad`,
  but only `ForceCategoriesToLoad()` calls it manually, so grepping for the symbol will find it
  and mislead). `ForceCategoriesToLoad()` itself has zero call sites, so adding a line to it
  changes nothing.
- **`BNCInitSessionResponse` is built at several separate sites** in `Branch.m`. A new field means
  updating all of them.
- **`BNCURLFilter` self-updates from the server after init**, so the runtime skip list can differ
  from the compiled-in default. Pin the pattern list in tests.

## For cross-platform tests

Never assert on session state or a session ID. Neither exists on iOS, and both are slated for
removal on Android. The portable definition of "session established" is: both randomized tokens
persisted, and the open callback or session-start notification fired.
