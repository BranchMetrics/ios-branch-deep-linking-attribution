# CLAUDE.md

Branch iOS SDK on the **`4.0.0-beta.*` rewrite line**. One Objective-C library, `BranchSDK`, for
iOS 12+ and tvOS 12+, shipped via SPM, CocoaPods, Carthage and prebuilt XCFrameworks. There is
no Swift under `Sources/` on this branch.

**This is not `master`.** The request queue, the session model, the wire endpoints and parts of
the public API all differ, and `master` carries its own CLAUDE.md describing the 3.x shape.
Porting a fix across the two lines is a rewrite, not a cherry-pick. Read
`docs/differences-from-master.md` before you try.

## Build and test

```bash
./scripts/getSimulator
xcodebuild test -project BranchSDK.xcodeproj -scheme BranchSDKTests \
  -destination "platform=iOS Simulator,name=$(cat ./iphoneSim),OS=latest" \
  -testPlan BranchSDKTests
```

**There is no fastlane and no Gemfile on this line.** Unit tests live in a first-class
`BranchSDKTests/` target inside `BranchSDK.xcodeproj`, not under `Branch-TestBed/`. A test added
to `Branch-TestBed/Branch-SDK-Tests/` will not run. Which workflows actually work, and which are
dead because they still shell out to fastlane: `docs/testing.md`.

## Rules that are easy to get wrong

- **Do not run `scripts/version.sh` on this branch.** The four version literals do not currently
  agree, and the script cannot reconcile them. See `docs/releasing.md` before touching any of them.
- **`BranchOpenRequest` is not `BranchRequestOpen`.** Both post to `/v3/events/open` and they are
  wired into different flows. Check which one you are editing.
- **Attribution level `NONE` drops a request inside `BNCServerRequestOperation`**, before the
  network layer. A request can be enqueued, report success, and never have been sent. Assert on
  the server interface, not on enqueue.
- **There is no session state to be in.** `BNCInitStatus` and `sessionID` are gone. Do not
  reintroduce an init status, a readiness latch, or a hold list keyed on session readiness.
  Ordering is solved with queue state (`containsInstallOrOpen`, the `currentInitOperation`
  dependency), never with a flag.
- **Session-dependent requests drop, they do not wait.** Missing either randomized token means an
  immediate `BNCInitError` in `-start`. No queue-level retry, no replay, no persistence. This is
  designed. Do not propose holding or replaying.
- **The init dependency is `weak`.** `currentInitOperation` going nil silently removes the gate.
  A hard ordering guarantee needs an explicit `addDependency:`.
- **Any AdSupport/IDFA touch must be `BRANCH_EXCLUDE_IDFA_CODE`-guarded**, and a new iOS-only API
  needs `#if !TARGET_OS_TV`. The podspec's tvOS exclusion covers CocoaPods only.
- **`release.yml`, `integration-tests.yml` and `version-bump.yml` do not run on this line.** They
  shell out to fastlane, which does not exist here, so a passing run is not a signal.

## Conventions

- Commit prefix `EMT-XXXX` (Jira). **PRs on this line target `4.0.0-beta.0`; check the base
  before opening, because the repo default is `master`.**
- Match the surrounding style: long-lived Objective-C, `@synchronized` blocks, explicit nil
  checks.
- `Public/` headers are an API contract. This branch already carries breaking changes, so a new
  one needs to be deliberate and recorded in `docs/differences-from-master.md`.
- Comments in shipped code state what a function does and what its parameters mean, nothing
  more. Reasoning belongs in the commit message and the PR body.
- `ChangeLog.md` is maintained by hand.

## Deeper reference

Read on demand. These are not loaded into context automatically, so open the one you need.

| Read this | Before |
| --- | --- |
| `docs/differences-from-master.md` | porting anything from `master`, or reading a `master` stack trace |
| `docs/code-map.md` | looking for where anything lives |
| `docs/architecture.md` | editing `BNCServerRequestQueue.m`, `BNCServerRequestOperation.m`, the `/v3` flow, or anything touching request ordering |
| `docs/testing.md` | adding a test, or trusting a CI result |
| `docs/releasing.md` | touching a version literal, the podspec, `Package.swift`, or anything IDFA or tvOS |
