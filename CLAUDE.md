# CLAUDE.md

Branch iOS SDK for deep linking and attribution. One Objective-C library, `BranchSDK`, for
iOS 12+ and tvOS 12+, shipped via SPM, CocoaPods, Carthage and prebuilt XCFrameworks.
Everything under `Sources/BranchSDK/` is `.h`/`.m`; there is no Swift in the shipped product
on this branch.

**This file describes `master` (3.x) only.** The `4.0.0-beta.*` line is a different
architecture (`NSOperationQueue` request queue, `/v3` endpoints, no `initSession`), is where
active development lands, and carries its own CLAUDE.md. Do not port an architecture claim across the two lines without checking.

## Build and test

```bash
bundle install                     # Ruby 2.7 + Bundler, needed once
bundle exec fastlane unit_tests    # the PR gate, exactly what CI runs

# Same tests without fastlane
xcodebuild test -project Branch-TestBed/Branch-TestBed.xcodeproj \
  -scheme Branch-TestBed-CI \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest"

# One class
xcodebuild test ... -only-testing:Branch-SDK-Tests/BNCRequestFactoryTests

xcodebuild -scheme xcframework     # build the distributable
```

Tests live under `Branch-TestBed/`, not next to `Sources/`. There is no style linter in this
repo. Details, test-plan layout and the other CI gates: `docs/testing.md`.

## Rules that are easy to get wrong

- **Never hand-edit the version.** It lives in four places and only `./scripts/version.sh`
  keeps them in sync. `fastlane version_bump` is broken here and patches paths that no longer
  exist. See `docs/releasing.md`.
- **Any AdSupport/IDFA touch must be `BRANCH_EXCLUDE_IDFA_CODE`-guarded**, or the no-IDFA
  build breaks at App Store review time rather than at compile time.
- **A new iOS-only API needs `#if !TARGET_OS_TV` in the source.** The podspec's
  `tvos.exclude_files` covers CocoaPods only; SPM and the XCFramework tvOS slice compile every
  file in `Sources/BranchSDK/`.
- **Adding a header to `Public/` is a public API change**, reviewed as a breaking change.
  Adding one to `Private/` is not.
- **Queue insertion order is attribution behavior, not an implementation detail.** Init is
  force-inserted at index 0 and a link-resolution open at index 1, deliberately behind it.
- **A new test target must be added to `Branch-TestBed-CI.xctestplan`** or CI will never run it.
- **`initSafetyCheck` looks like dead defensive code and is not.** If status is `Uninitialized` it
  silently starts an init rather than erroring, so an app that never calls `initSession` can still
  emit requests. Load-bearing for backward compatibility. Do not clean it up.
- **Mutating session state outside `Branch.isolationQueue` is the standard way to introduce a
  race here.** Nearly every public entry point hops onto that serial queue first.

## Conventions

- Commit prefix `EMT-XXXX` (Jira). Branch off and PR into `master`.
- Match the surrounding style: long-lived Objective-C, `@synchronized` blocks, explicit nil
  checks. Do not import a newer idiom into one file.
- Comments in shipped code state what a function does and what its parameters mean, nothing
  more. Reasoning belongs in the commit message and the PR body.
- `ChangeLog.md` is maintained by hand, per release.

## Deeper reference

Read on demand. These are not loaded into context automatically, so open the one you need.

| Read this | Before |
| --- | --- |
| `docs/code-map.md` | looking for where anything lives |
| `docs/architecture.md` | editing `Branch.m` init or queue paths, `BNCServerRequestQueue.m`, `BNCPreferenceHelper.m`, or adding a category or a `BNCInitSessionResponse` field |
| `docs/testing.md` | adding a test, adding a test target, or reading a CI failure |
| `docs/releasing.md` | touching a version literal, the podspec, `Package.swift`, or anything IDFA or tvOS |
