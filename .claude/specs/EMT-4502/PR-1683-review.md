# Review: PR #1683 (EMT-4502, manual send of opens)

Base `4.0.0-beta.2`, head `9a9189dc`, the same as the local branch. Reviewed against
`2026-10-02-automatic-open-events-design.md` (Android) and `iOS plan Updated (1).md`.
The PR was not built and the tests were not run; everything below comes from reading the code.

## Summary

The core of the iOS plan is in place and works the way the plan says. With
`automaticOpenEvents = NO`, a resolved link's open is held. `-sendOpen` waits behind any
unfinished resolves (D12) and reads the held link data when the request is built, not when it is
queued. The background flush runs under a background task, and the flush and `-sendOpen` share one
lock so they can't both send the same held link. The new test file covers most of the plan's
Steps 8–11.

Several plan items are missing, though, and the PR does one thing neither spec asks for: it removes
three public APIs.

## Should block merge

### 2. Likely double open in the default mode, because the plan's D3 "supersede" rule wasn't built

- A resolve that finds no link now sends its own unattributed open (`BranchRequestDeepLink.m`
  `-attemptToSendOpen:`, else branch, via `sendAutomaticUnattributedOpen`).
- That open is held back only by `openSentThisForegroundPeriod` and `hasUnfinishedInstallOrOpen`.
  Neither one looks at a deep-link resolve still waiting in the queue.
- So an app that calls the resolve from both its AppDelegate and its SceneDelegate gets a no-link
  resolve (unattributed open) followed by a URL resolve (attributed open): two opens in one launch.
- The plan names this exact case (window #3) as becoming a reliable double open once the no-link
  resolve sends its own open, and adds Step 6 to prevent it. `hasPendingDeepLinkRequestOtherThan:`
  was never added, and no test covers a no-link resolve followed by a URL resolve.

### 3. A held link open can be stuck until the next background (`flushHeldAttributedOpenOnBackground`)

- The flush returns early whenever *any* install or open is unfinished. The plan's rule was
  narrower: skip only when a *manual open is pending* that will take the held link.
- How it happens in manual mode:
  1. The app calls `-sendOpen` with nothing held. The open is queued, runs, and reads nil as its
     link data.
  2. A universal link then resolves, and its response is held.
  3. The user backgrounds the app while that first open is still on the network.
  4. The flush sees an unfinished open and returns. No later open will pick up the held link.
- The held link then waits for a later `-sendOpen` or the next background. If the process is killed
  first, the attribution is lost.

### 4. The docs required by the plan (D7, Step 12) are missing

- No changes to `docs/differences-from-master.md`, `docs/architecture.md` or `ChangeLog.md`.
- `docs/architecture.md:67-70, 78` is now wrong. It says a no-link resolve sends nothing, and that
  "Opens come from foreground or an explicit call, nothing else … do not create one from any other
  path". This PR adds opens from a no-link resolve and from the background flush.
- The change for existing `automaticOpenEvents = NO` apps (plan risk R12) is also not documented.

## Where the PR differs from the specs (needs a decision, not necessarily a fix)

- **Organic launch in manual mode with no `-sendOpen`.** The background flush only sends a *held
  link*. An organic or failed-resolve launch where the app never calls `-sendOpen` sends no open at
  all. On a first install, no install is ever recorded until the app calls it. Android sends the
  kept open at background even with no link reply (Android R4/R12), following Justin's point that
  "an open must never be lost". This matches the iOS plan, but the two platforms disagree.
- **Second open after the ATT prompt.**
  - Commits `adf81c86` and `9a9189dc` reverse plan D2 for automatic mode: an activation after a
    resign sends a new open again.
  - Manual mode doesn't get this (`testResignWithoutBackgroundDoesNotRearmManualSendOpen`). A
    manual-mode app that calls `-sendOpen` after the ATT prompt gets dropped by the
    once-per-period guard, so the open carrying the "authorized" status never goes out.
  - The reason given in the commits (`opted_in_status`) applies equally to manual mode.
- **`-sendOpen` in automatic mode.** iOS sends an unattributed open (plan D9). Android's R14 does
  nothing and logs a warning.
- **Opt-in while attribution is NONE.** iOS throws the held link away when `-sendOpen` is called at
  NONE. Android remembers the call and sends the open at opt-in (R9/R11).
- **No warning log for events sent before the open.** Android's section 8 adds a one-time log line
  for events, LATD or QR codes requested before the open. iOS only mentions it in the config
  comment.
- **Plan Step 7 (D10)**, which makes the scene activity selection deterministic, isn't implemented.
  That's fine if it was deliberately dropped, but the PR body should say so.

## Smaller items

- **Background task not ended on two paths.**
  - If attribution is NONE when the flush runs, `enqueueAttributedOpenWithResponseData:` returns
    early without calling `completion`.
  - Separately, `BNCServerRequestOperation` drops opens at NONE without calling their callback.
  - In both cases the background task is only ended by its expiration handler, and
    `clearLinkIdentifiers` doesn't run.
- **Dead code.**
  - Nothing calls `-sendOpen:skipCallback:` any more; it is now a one-line forwarder.
  - The `skipCallback` parameter of `handleResolvedLinkResponse:` is unused.
- **Duplicated enqueue code.** `enqueue:afterUnfinishedDeepLinkRequests:` copies almost all of
  `enqueue:withPriority:`. It could share a helper that takes the extra dependencies.
- **Delegate called inside a lock.** `enqueueManualOpen` calls `branch:willStartSessionWithURL:`
  while holding `@synchronized (self)`, taken in `-sendOpen`. App code then runs inside the SDK's
  lock, which risks a deadlock.
- **Too-broad "already pending" check.** It uses `hasUnfinishedInstallOrOpen`, which also counts an
  open that is already running and has already read its link data. A `-sendOpen` in that window is
  dropped even though a newly held link is waiting. Checking only for a manual open that hasn't
  started yet, as the plan specifies, fixes this and item 3 together.
- **PR housekeeping.**
  - The deleted `Branch-TestBed/Branch-SDK-Tests/BranchDisableNextForegroundTests.m` never ran
    anyway, so that deletion is harmless.
  - The existing test `testAutomaticOpenTrackingDisabledAtTheDeferredReReadSendsNoOpen` was removed
    rather than re-pointed at the new property.
  - No "Type of change" box is ticked in the PR body.
