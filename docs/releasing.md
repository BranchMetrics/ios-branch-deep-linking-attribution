# Versioning and packaging (4.0.0-beta)

## Do not run `scripts/version.sh` on this branch

Current state on this branch:

| Where | Value |
| --- | --- |
| `Sources/BranchSDK/BNCConfig.m` (`BNC_SDK_VERSION`) | `4.0.0-alpha.0` |
| `BranchSDK.podspec` (`s.version`) | `4.0.0-alpha.0` |
| `scripts/version.sh` (`version=`) | `4.0.0` |
| `BranchSDK.xcodeproj` (`MARKETING_VERSION`) | `3.12.1` |

Running `version.sh -i` or `-u` drops the `-alpha.0` suffix, and because `prev_version` comes
from the script's own stale literal, the `MARKETING_VERSION` rewrite matches nothing. The result
is a repo that is *more* divergent than before.

`fastlane version_bump` is not an alternative either: fastlane was deleted on this line.

Leave the version alone unless the task is specifically to reconcile it, and reconcile it by hand
with the four values above in front of you.

## Distribution vehicles

All built from `Sources/BranchSDK/**/*.{h,m}`.

- **SPM**: `Package.swift`. The target `path` is narrowed to `Sources/BranchSDK` (master uses
  `Sources`), so `publicHeadersPath` and `headerSearchPath` are plain `Public` and `Private`
  rather than master's `BranchSDK/`-prefixed forms. Both resolve relative to `path`.
- **CocoaPods**: `BranchSDK.podspec`. tvOS **excludes** `BNCContentDiscoveryManager`,
  `BNCUserAgentCollector` and `BNCSpotlightService`.
- **XCFramework**: schemes `xcframework`, `xcframework-noidfa`, `static-xcframework`.

## Two build-variant traps

**IDFA-free variants** are the same sources compiled with `BRANCH_EXCLUDE_IDFA_CODE=1`. Guard any
new AdSupport or IDFA touch with that macro, or the no-IDFA build breaks at App Store review time
rather than at compile time.

**tvOS support is the `#if !TARGET_OS_TV` guard in the source.** The podspec's
`tvos.exclude_files` covers CocoaPods only; SPM and the XCFramework tvOS slice compile every file
under `Sources/BranchSDK/`.

## Release

`release.yml` is currently **non-functional on this line** because it shells out to fastlane. Do
not rely on it.

`ChangeLog.md` is maintained by hand. `sync-readme-changelog.yml` does not touch it: on a
published release it pushes the release body to ReadMe.io and announces in Slack.
