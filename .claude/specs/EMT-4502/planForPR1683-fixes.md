# PR #1683 review fixes: plan

Derived from `PR-1683-review.md`, the user's direction on it (2026-10-09), and the Android implementation
on `android-branch-deep-linking-attribution` `origin/gdeluna-branch/manualSendOpen` (`Branch.java:1740-1950`,
`BranchRequestQueueAdapter.kt:84`, `TrackingController.java:96`). Implemented on `bboothe-branch/EMT-4502`
(`9a9189dc`, PR #1683), per Q1. Line numbers below are for this branch. `EMT-4542` is rebased onto the result
afterwards (Step 9).

> **Status: Q1–Q4 answered 2026-10-09; steps updated to match. Awaiting approval of the steps. Nothing is
> implemented.**

---

## 1. Review findings, validated

| # | Review item | Verdict | Evidence (this branch) | Action |
|---|---|---|---|---|
| 2 | Double open: the plan's D3 supersede rule was never built | **True, but deliberate.** The review read an older plan copy (`iOS plan Updated.md`, which still has D3 and D10). The approved plan dropped D3 on 2026-10-05 and recorded the window as R2, to be fixed in the separate scenes PR | `planForEMT4502.md:16-20, 105-106, 491-497` | None. PR body should say so |
| 3 | A held link open can be stuck until the next background | **Confirmed** | `-flushHeldAttributedOpenOnBackground` returns on `hasUnfinishedInstallOrOpen`, which also counts an open that is already running and has already read nil link data | Step 3 |
| 4 | Docs (`differences-from-master`, `architecture`, `ChangeLog`) missing | **True, but deliberate.** D7 was rejected by the user on 2026-10-05; the PR body is the record | `planForEMT4502.md:24-27` | None. `docs/architecture.md:67-70, 78` is still factually stale; reported, not edited |
| — | Manual mode, organic or failed launch, no `-sendOpen`: no open at all | **Confirmed.** Background only flushes a *held link*; with nothing held it only clears identifiers. On first install no install is ever recorded | `-flushHeldAttributedOpenOnBackground` final branch | **Step 4** (user: must send an open at background) |
| — | Second open after the ATT prompt is automatic-mode only | **Confirmed** | `-applicationWillResignActive` only sets `resignedSinceActivation` when `automaticOpenEvents`; `-applicationDidBecomeActive` returns before the re-arm in manual mode; `testResignWithoutBackgroundDoesNotRearmManualSendOpen` pins it | **Step 5** (user: manual mode needs it too) |
| — | `-sendOpen` in automatic mode sends an open (iOS D9) vs Android R14 logs and does nothing | Confirmed difference | `-sendOpen` first branch | None. You didn't ask for this one. Say so if you want parity |
| — | `-sendOpen` at NONE throws the held link away | **Confirmed.** It nils `_heldAttributedOpenResponse` and clears identifiers. Android keeps the open and sends it at opt-in | `-sendOpen` NONE branch (`Branch.m:2287`); Android `sendOpen` → `openWaiters_`, `onTrackingEnabled` → `sendHeldOpen` | **Step 6** (user: must match, never lose an open) |
| — | No one-time warning for events, LATD or QR before the open | **Confirmed.** Android logs once per process from `handleNewRequest` | Android `warnIfOpenWaitsForSendOpen` | **Step 7** |
| — | Plan Step 7 (D10) not implemented | **True, but deliberate.** Dropped with D3 on 2026-10-05. See section 3 | `planForEMT4502.md:137-138` | None. PR body should say so |
| small | Background task not ended at NONE | **Confirmed, both paths.** `-enqueueAttributedOpenWithResponseData:completion:` returns before calling `completion`. `BNCServerRequestOperation -start` drops an open at NONE without any callback, and a cancelled operation (`clearNetworkQueue`) also finishes silently | `Branch.m` NONE early return; `BNCServerRequestOperation.m:110-123, 99-102` | Step 4 |
| small | Dead code: `-sendOpen:skipCallback:`, unused `skipCallback` | **Confirmed, and wider.** `attemptToSendOpen:response:skipCallback:` only passes `skipCallback` on to `-handleResolvedLinkResponse:skipCallback:`, which ignores it | `Branch.m:2436`; `BranchRequestDeepLink.m:23, 86, 96, 282, 310` | Step 2 |
| small | `enqueue:afterUnfinishedDeepLinkRequests:` duplicates `enqueue:withPriority:` | **Confirmed** | `BNCServerRequestQueue.m:69-125` | Step 1 |
| small | Delegate called inside `@synchronized (self)` | **Confirmed.** `-sendOpen` holds the lock across `-enqueueManualOpen`, which calls `branch:willStartSessionWithURL:` | `-sendOpen` (`Branch.m:2295-2309`), `-enqueueManualOpen` | Step 2 |
| small | "Already pending" check too broad | **Confirmed.** Same root cause as #3 | `-sendOpen` duplicate guard (`Branch.m:2296`) | Step 3 |
| small | Removed test `testAutomaticOpenTrackingDisabledAtTheDeferredReReadSendsNoOpen` | True. Part 2 deleted it on purpose: its gate is only reachable through a runtime toggle (`planForEMT4502-part2.md:31-42`). That toggle is `+updateConfiguration:`, which exists only on `EMT-4542` | — | Step 9 re-adds it on `EMT-4542`, config-driven |

**Duplicated code the review didn't list:** the three open builders (`-enqueueUnattributedOpen`,
`-enqueueManualOpen`, `-enqueueAttributedOpenWithResponseData:completion:`) each repeat the delegate call, the
same 12-line callback block, the `isInstall` check and the request setup. `-sendOpen`'s NONE branch repeats the
NONE log line from both enqueue methods. Step 2 folds them.

**What changes when `EMT-4542` is rebased onto this.** `208f4d4b` and `9313fd0a` touch configuration and DMA only,
and fix none of the above. `+updateConfiguration:` there can leave NONE through
`-setConsumerProtectionAttributionLevel:resetSession:YES`, so Step 6 puts the opt-in send inside that method,
where it covers the public setter here and `+updateConfiguration:` after the rebase with no extra code. Spec
part 2 item 7 ("on NO→YES, flush the held response") was not built on `EMT-4542`; after Step 4 a held response
goes out at the next background, so it isn't lost. Step 9 adds the tests for both.

---

## 2. Design after the fixes

**Manual mode (`automaticOpenEvents = NO`) gets exactly one open per foreground period, and never zero.** It
comes from the app's `-sendOpen` or, failing that, from the background. Either way it's the same request: a
manual open enqueued behind every unfinished resolve, which takes the held response when it's built. So:

- The background flush stops being a separate "send the held response" path. It enqueues a manual open whenever
  this period has no open sent and none pending, or a response is held. This one rule covers an organic launch, a
  failed resolve, a held link, a resolve still in flight at background, and the first install.
- "Pending" means a manual open that hasn't started yet (`-hasPendingManualOpen`), not any unfinished open. That
  fixes review #3 and the too-broad guard together.
- A resolve that completes in the background holds its response when a manual open is pending, instead of
  sending its own open (today's D4). Without this, a background open waiting on that resolve would read nil and
  the resolve would send a second, attributed open.

**Attribution NONE never loses an open, in either mode (Q2).** At NONE, a resolve with a link holds its response
in any app state, and a `-sendOpen` or background flush that would have sent records that an open is owed. The
held response and link identifiers are kept. Moving from NONE to any other level sends the owed or held open,
attributed if a response is held. This is Android's `openWaiters_`/`owed` + `sendHeldOpen` behaviour.

**ATT:** a resign followed by an activation re-arms the period marker in both modes. In manual mode the
background flush may then send a second open carrying the new `opted_in_status` (Q3, accepted).

---

## 3. What "Plan Step 7 (D10)" means

`-requestDeepLinkDataWithSceneOptions:` (and `-requestDeepLinkDataWithScene:openURLContexts:`) picks
`connectionOptions.userActivities.allObjects.firstObject` (`Branch.m:2206, 2216, 2229`). An `NSSet` has no order,
so if iOS hands a scene more than one activity or URL, which one gets resolved is arbitrary. D10 would have
picked the `NSUserActivityTypeBrowsingWeb` activity explicitly and logged a warning for more than one URL
context. You moved it, together with the scenes double-open fix (D3), to the separate scenes PR on 2026-10-05.
**No code change in this plan.** The PR body only needs one line saying both were moved out on purpose.

---

## 4. Decisions (answered 2026-10-09)

| Q | Question | Answer | Where it lands |
|---|---|---|---|
| Q1 | Which branch? | **`bboothe-branch/EMT-4502` (PR #1683).** Rebase `EMT-4542` onto it afterwards | Steps 1–8 here; Step 9 on `EMT-4542` |
| Q2 | Attribution NONE in automatic mode | **Match Android in both modes.** A link opened at NONE is held and attributed at opt-in. `testAttributionNoneResolveWithLinkSendsNoOpenAndClearsIdentifiers` inverts | Step 6 |
| Q3 | Manual-mode background flush after the ATT re-arm can send a second open | **Accept.** Same open automatic mode sends after the prompt, later; the backend dedups it. No second marker | Step 5 test |
| Q4 | The "owed open" state for NONE | **Yes, one in-memory BOOL `openOwedAtOptIn`.** Maximum Android parity. Keyed on attribution level, not session readiness, so outside the `CLAUDE.md` ban; called out in the PR body | Step 6 |

---

## 5. Comment rule (unchanged from part 1)

Two sentences max, saying what the code is and does. No ticket numbers, decision labels (`D4`, `Q2`),
path letters, step numbers or reasoning. This includes rewriting the ATT comment `9a9189dc` added (three
sentences, with reasoning) when it's touched in Step 5.

## 6. Verify

Per step: iterate on the touched test classes only, then the full suite **once** at the end of the step. Steps
that touch `Sources/` also build tvOS and the static target.

```bash
./scripts/getSimulator
xcodebuild test -project BranchSDK.xcodeproj -scheme BranchSDKTests \
  -destination "platform=iOS Simulator,name=$(cat ./iphoneSim),OS=latest" -testPlan BranchSDKTests \
  -only-testing:BranchSDKTests/BranchDeferredAttributedOpenTests \
  -only-testing:BranchSDKTests/BranchLifecycleOpenResolveTests \
  -only-testing:BranchSDKTests/BranchSessionParamsClearTests
xcodebuild test -project BranchSDK.xcodeproj -scheme BranchSDKTests \
  -destination "platform=iOS Simulator,name=$(cat ./iphoneSim),OS=latest" -testPlan BranchSDKTests
xcodebuild build -project BranchSDK.xcodeproj -target BranchSDK-tvOS -sdk appletvos -configuration Release CODE_SIGNING_ALLOWED=NO
xcodebuild build -project BranchSDK.xcodeproj -target BranchSDK-static -sdk iphoneos -configuration Release CODE_SIGNING_ALLOWED=NO
```

---

## 7. Steps

All on `bboothe-branch/EMT-4502` except Step 9. Steps 1–2 are refactors with no behaviour change, so the whole
suite stays green. Steps 3–7 write their tests first, show them failing, then implement.

- TODO: **Step 1: Queue helpers (refactor + one new query).**
  `BNCServerRequestQueue.m`:
  - Fold `-enqueue:withPriority:` and `-enqueue:afterUnfinishedDeepLinkRequests:` into one private
    `-enqueue:withPriority:afterUnfinishedDeepLinkRequests:(BOOL)`. Both public selectors become one-line callers.
    `-enqueue:afterUnfinishedDeepLinkRequests:` also returns the operation it adds (`NSOperation *`), so Step 4
    can attach a completion block. Update the category declaration in `Branch.m` (`DeferredForegroundOpen`,
    `:129-135`).
  - Add `-hasPendingManualOpen`: an unfinished, **not executing**, uncancelled operation whose request is a
    `BranchRequestOpen` with a non-nil `linkDataResolver`. Declare it in the same category.
  Tests: none new. The suite stays green.

- TODO: **Step 2: Dead and duplicated code in the open senders (refactor).**
  - Delete `-sendOpen:skipCallback:` (`Branch.m:2436`, no callers).
  - Drop `skipCallback` from `-handleResolvedLinkResponse:` and from `BranchRequestDeepLink
    -attemptToSendOpen:response:` (both call sites, `BranchRequestDeepLink.m:86, 96`), and from the forward
    declarations (`Branch.m:190`, `BranchRequestDeepLink.m:23`).
  - Add one private builder, `-openRequestWithCompletion:(nullable dispatch_block_t)`, that notifies
    `branch:willStartSessionWithURL:`, builds the shared callback, sets `isInstall`, `urlString` and
    `traceCallback`, and returns the `BranchRequestOpen`. The three enqueue methods use it, leaving only what
    differs: `linkData`, `linkDataResolver`, and which enqueue selector is called.
  - Move the delegate call out of `@synchronized (self)`: `-sendOpen` builds the request before taking the lock
    and enqueues it inside the lock. A request built and then dropped by the duplicate guard has already called
    the delegate; build it only after the guard's cheap checks pass, then re-check under the lock.
  Tests: the suite stays green. (The removed deferred re-check test needs `+updateConfiguration:`; Step 9.)

- TODO: **Step 3: "Pending" means a manual open that hasn't started (review #3 and the too-broad guard).**
  - `-sendOpen` duplicate guard: `hasUnfinishedInstallOrOpen` → `hasPendingManualOpen`.
  - `-flushHeldAttributedOpenOnBackground` early return: same replacement.
  - `-handleResolvedLinkResponse:` background branch: hold instead of sending when `hasPendingManualOpen`.
  Tests first:
  - Review #3 sequence: manual `-sendOpen` with nothing held (open in flight, stub response suspended), a URL
    resolve finishes and holds, background → a second, attributed open goes out at background.
  - `-sendOpen` while the first manual open is in flight and a newly held link is waiting → one attributed open.
  - Background with a manual open pending and a resolve finishing *after* the background → exactly one open, the
    attributed one.
  - Existing `testManualOpenPendingAtBackgroundWithHeldResponseSendsExactlyOneOpen`,
    `testOneHundredSendOpenCalls…` and `testManualSendOpenAndBackgroundFlushRace…` stay green.

- TODO: **Step 4: Manual mode always sends an open at background (organic, failed resolve, install).**
  Rename `-flushHeldAttributedOpenOnBackground` to `-sendOpenAtBackground`. Under the existing lock:
  1. `hasPendingManualOpen` → return; that open goes out.
  2. A response is held (either mode), **or** manual mode and `!openSentThisForegroundPeriod` → enqueue through
     the same manual-open path as `-sendOpen`, behind unfinished resolves. Start the background task first. End
     it from the returned operation's `completionBlock`, which runs on success, failure, the NONE drop inside
     `BNCServerRequestOperation` and cancellation alike. This fixes the review's stuck-background-task item
     without touching `BNCServerRequestOperation`.
  3. Otherwise keep today's identifier clear (manual mode, nothing unfinished).
  This replaces the held-only flush, so `-enqueueAttributedOpenWithResponseData:completion:` loses its now-unused
  `completion` parameter. The open's own response handling already clears link identifiers
  (`BranchRequestOpen.m:191-197`). The flush's extra `clearLinkIdentifiers` on failure goes away, because
  identifiers must survive an open that didn't send (Step 6).
  Tests first:
  - Manual mode, no resolve, no `-sendOpen`, background → one open, `is_install`/install path when no
    `randomizedBundleToken`, and the background task begun and ended.
  - Manual mode, no-link resolve, no `-sendOpen`, background → one unattributed open.
  - Manual mode, failed resolve (`BranchResolveStubModeError`), background → one open.
  - Manual mode, resolve still in flight at background → exactly one open, attributed, sent after the resolve.
  - Manual `-sendOpen`, then background → no second open (existing test stays green).
  - Automatic mode, resolve with a link completing in the background (held), background → one attributed open.
  - Background task ended when the flushed open is dropped at NONE inside the operation.
  Tests that change: `testBackgroundWithNothingHeldAndEmptyQueueClearsIdentifiers` now also sends an open. Keep
  the identifier assertion only if it still holds after the open's response; otherwise list it before changing.

- TODO: **Step 5: The ATT re-arm applies in manual mode too.**
  - `-applicationWillResignActive`: set `resignedSinceActivation` in both modes (`Branch.m:1697`).
  - `-applicationDidBecomeActive`: consume `resignedSinceActivation` and reset the marker *before* the
    `!automaticOpenEvents` early return (`Branch.m:1572` vs `:1580`). Rewrite the comment to two sentences.
  - Update the `openSentThisForegroundPeriod` and `resignedSinceActivation` property comments (`Branch.m:171-176`).
  Tests first:
  - Invert `testResignWithoutBackgroundDoesNotRearmManualSendOpen` → `…RearmsManualSendOpen`: two opens.
  - Q3: manual `-sendOpen`, resign → active, no second call, background → a second open.
  - A manual open still pending at the resign: the `-sendOpen` after activation is dropped by the duplicate guard.

- TODO: **Step 6: Attribution NONE keeps the open and sends it at opt-in, in both modes** (Q2, Q4).
  - Add private `openOwedAtOptIn` (BOOL, `@synchronized (self)` accessors). In `+applyConfiguration:toBranch:`
    clear it, and the held response, **before** the `setConsumerProtectionAttributionLevel:resetSession:NO` call
    (`Branch.m:348-350`), so a reconfigured test singleton can't send a stale owed open from that call.
  - `-sendOpen` at NONE: keep the held response and the identifiers, set the owed flag, log at debug level.
  - `-sendOpenAtBackground` at NONE: when case 2 of Step 4 applies, set the owed flag instead of enqueuing (no
    background task).
  - `-handleResolvedLinkResponse:` at NONE: hold in any app state, in both modes. Identifiers are kept.
    `-shouldSendAutomaticUnattributedOpen` already returns NO at NONE.
  - `-setConsumerProtectionAttributionLevel:resetSession:` to NONE: if `hasPendingManualOpen` before
    `clearNetworkQueue`, set the owed flag. The resolver hasn't run, so the held response is still there.
  - Leaving NONE (same method): read the previous level from `preferenceHelper` before overwriting it. Only when
    it was NONE and the new level isn't: if owed or a response is held, clear the flag and enqueue the
    manual-path open (attributed when held). This runs regardless of `resetSession` and of mode. Otherwise keep
    today's automatic-mode `resetSession` open. Never both. A FULL→FULL set doesn't flush a held response early.
  Tests first (replacing `testSendOpenUnderAttributionNoneConsumesTheHeldResponseAndClearsIdentifiers`):
  - Manual: held link, NONE, `-sendOpen` → nothing on the wire, held response and identifiers kept; opt-in through
    `-setConsumerProtectionAttributionLevel:` → one attributed open.
  - Manual: NONE, nothing held, background → nothing; opt-in → one unattributed open.
  - Manual: NONE, no `-sendOpen`, no background, opt-in → no open
    (`testAttributionLevelResetFromNoneToFullWithAutomaticOpenEventsNoSendsNoOpen` stays green).
  - Manual open pending, switch to NONE, switch back → exactly one open.
  - Automatic: NONE, URL resolve → no open, identifiers kept; opt-in → one attributed open, not followed by the
    `resetSession` unattributed open. Inverts `testAttributionNoneResolveWithLinkSendsNoOpenAndClearsIdentifiers`;
    `testAttributionLevelResetFromNoneToFullSendsOneOpen` stays green.
  - Automatic: held response at FULL (background resolve), set FULL again → no open until background.

- TODO: **Step 7: One-time warning for events, LATD and QR codes before the open.**
  Add private `-warnIfOpenWaitsForSendOpen`. Manual mode only, once per process (a `dispatch_once`-style
  static), and only when this period has no open sent and none pending. It logs through `logWarning:` (iOS has
  no always-on level):
  `"Branch logEvent, LATD or QR code was requested before sendOpen. On the first launch after install, events fail with BNCInitError until the open is sent; later they reach Branch before the open."`
  Call sites: `-sendServerRequest:` (every `BranchEvent`), `-lastAttributedTouchDataWithAttributionWindow:completion:`,
  and `BranchQRCode -getQRCodeAsData:linkProperties:completion:` (through a forward-declared category, the same
  pattern `BranchRequestDeepLink.m` uses).
  Tests first, capturing logs through `+[Branch enableLoggingAtLevel:withCallback:]`:
  - Manual mode, `logEvent` before `-sendOpen` → the warning, once, even after a second event and an LATD call.
  - Automatic mode → no warning.
  - Manual mode after `-sendOpen` → no warning.
  The "once" static needs a test reset hook, next to `resetInitializationGuardForTesting` (`Branch.m:227`).

- TODO: **Step 8: Header docs and final verification.**
  - `BranchConfiguration.h` `automaticOpenEvents` and `Branch.h` / `BranchInterface.h` `-sendOpen`: say that
    with NO, an open is sent at background if the app hasn't sent one that period, that a call made at NONE is
    sent at opt-in, and that the ATT re-arm applies. These are header doc comments, not repo docs.
  - Full suite, tvOS and static builds, iOS archive.
  - Append part 3 questions to `quiz.md`.
  - No `docs/`, `ChangeLog.md` or PR body edits. You write the PR body. Things it should cover, for your use:
    D3 and D10 moved to the scenes PR; the background open in manual mode (R12 changes again: an app that sets NO
    and never calls `-sendOpen` now records an open every period, not only when a link is held); NONE opt-in
    behaviour in both modes, including that a link opened at NONE is attributed after opt-in (Q2); the owed flag
    vs `CLAUDE.md` (Q4); the second manual-mode open after the ATT prompt (Q3).
  - Commit only after approval, `EMT-4502` prefix. No push without approval.

- TODO: **Step 9: Rebase `EMT-4542` and add the `+updateConfiguration:` tests (on `EMT-4542`, not #1683).**
  After Steps 1–8 are committed and approved, rebase `bboothe-branch/EMT-4542` onto `EMT-4502`. Expect conflicts
  in `Branch.m` around `+applyConfiguration:toBranch:` and `-setConsumerProtectionAttributionLevel:resetSession:`;
  keep Step 6's ordering (clear owed and held state before the attribution-level call). Then, tests only:
  - Re-add `testAutomaticOpenTrackingDisabledAtTheDeferredReReadSendsNoOpen`: `automaticOpenEvents = NO` applied
    through `+updateConfiguration:` **after** the deferred check is armed → the deferred re-check sends no open.
  - Automatic mode, response held, `+updateConfiguration:` flips `automaticOpenEvents` NO→YES, background → one
    attributed open.
  - Manual: held link, NONE, `-sendOpen`, opt-in through `+updateConfiguration:` → one attributed open.
  Same verify commands, on `EMT-4542`. No push without approval.

---

## 8. Risks

- **R12 widens.** Every existing `automaticOpenEvents = NO` app now sends an open at every background where it
  didn't call `-sendOpen`. That's the intent ("never lose an open"), but it's a wire-visible change.
- **Background enqueue still depends on the OS reporting the background.** Force-quit while suspended, jetsam and
  crashes still lose the open (R8, unchanged).
- **Q2 privacy (accepted).** A link clicked at NONE is held and attributed after opt-in, in both modes. The held
  response is in memory only, so a relaunch before opt-in drops it.
- **`BranchSessionParamsClearTests` manual-mode test** already depends on the flush. Step 4 changes the flush.
  If the stub's open response overwrites `sessionParams`, stop and report; don't loosen the assertion.
- **Step 9 rebase.** `EMT-4542` rewrites part of `+applyConfiguration:toBranch:` (173 lines of `Branch.m`).
  Conflicts are expected; resolve them, don't drop either side.
- **`docs/architecture.md:67-70, 78`** stays wrong after this PR (no repo-doc edits, by your rule). Reported only.
