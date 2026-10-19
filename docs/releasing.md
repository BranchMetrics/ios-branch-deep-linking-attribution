# Versioning, packaging and release (master, 3.x)

## Version lives in four places

All four are rewritten by `scripts/version.sh` and must agree.

| Where | What |
| --- | --- |
| `scripts/version.sh` | the `version=` literal the script reads back, so effectively the source of truth |
| `Sources/BranchSDK/BNCConfig.m` | `BNC_SDK_VERSION` |
| `BranchSDK.podspec` | `s.version` |
| `BranchSDK.xcodeproj/project.pbxproj` | `MARKETING_VERSION`, in 6 build configurations |

```bash
./scripts/version.sh        # print current version
./scripts/version.sh -i     # increment patch and update all four
./scripts/version.sh -u     # update the files to the current version, no increment
```

**Never hand-edit any of them.** And do not reach for `bundle exec fastlane version_bump` or
the `version-bump.yml` workflow: `fastlane/lib/helper/version_helper.rb` still patches
`carthage-files/`, `Branch-SDK/BNCConfig.m`, `Branch.podspec` and
`Branch-TestBed/Framework-Info.plist`, none of which exist on this branch.

## Distribution vehicles

All built from `Sources/BranchSDK/**/*.{h,m}`.

- **SPM**: `Package.swift`, target `BranchSDK`, `publicHeadersPath: BranchSDK/Public/`. Private
  headers are reachable only via the `BranchSDK/Private` header search path.
- **CocoaPods**: `BranchSDK.podspec`. tvOS **excludes** `BNCContentDiscoveryManager`,
  `BNCUserAgentCollector` and `BNCSpotlightService`.
- **XCFramework**: `BranchSDK.xcodeproj` schemes `xcframework`, `xcframework-noidfa`,
  `static-xcframework`, driven by `scripts/build_xcframework*.sh` and `scripts/prep_*`.
- **Carthage** and prebuilt XCFrameworks for manual integration.

## Two build-variant traps

**IDFA-free variants** are the *same* sources compiled with
`GCC_PREPROCESSOR_DEFINITIONS=BRANCH_EXCLUDE_IDFA_CODE=1`. Any new AdSupport or IDFA touch must
be guarded by that macro, or the no-IDFA build breaks at App Store review time rather than at
compile time.

**tvOS support is the `#if !TARGET_OS_TV` guard in the source**, not the podspec exclusion.
`Package.swift` and the XCFramework tvOS slice compile *every* file under `Sources/BranchSDK/`
with no exclusions. The three excluded files are listed in `s.tvos.exclude_files` **and** wrapped
in `#if !TARGET_OS_TV`; the guard is what makes tvOS build. A new iOS-only API needs the guard,
and the podspec exclusion alone will break SPM and XCFramework tvOS builds.

## Release workflow

`release.yml` builds and signs the XCFrameworks with checksums, gated by a `static-analysis` job
running `xcodebuild analyze`. `scripts/prep_release.sh` runs `pod lib lint`.

`ChangeLog.md` is maintained by hand, per release. `sync-readme-changelog.yml` does **not** read
it: on a published GitHub release it pushes the release body to the hosted ReadMe.io page
`ios-version-history` and announces in Slack. Nothing writes into this repo's `README.md`.
