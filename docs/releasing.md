# Versioning and packaging (4.0.0-beta)

## Version numbers

Versions are `Major.Minor.Patch` with an optional `-alpha.N`, `-beta.N` or `-rc.N` suffix, e.g.
`4.0.0-beta.2`. Git tags use the same string, with no `v` prefix: the podspec's source tag is
`s.version`, and the SPM repo dispatch passes the tag through unchanged.

`scripts/version.sh` owns four literals:

| Where | Value |
| --- | --- |
| `scripts/version.sh` (`version=`) | full version, e.g. `4.0.0-beta.2` |
| `Sources/BranchSDK/BNCConfig.m` (`BNC_SDK_VERSION`) | full version |
| `BranchSDK.podspec` (`s.version`) | full version |
| `BranchSDK.xcodeproj` (`MARKETING_VERSION`, `BranchSDK`, `-static` and `-tvOS` targets only) | `Major.Minor.Patch`, e.g. `4.0.0` |

`MARKETING_VERSION` never carries the suffix. It becomes the framework's
`CFBundleShortVersionString`, which App Store validation requires to be at most three integers
(ITMS-90060), and the check runs on embedded frameworks in customer apps. The test targets'
`MARKETING_VERSION` is not touched.

```bash
./scripts/version.sh                    # print: 4.0.0-beta.2
./scripts/version.sh -s 4.0.0-beta.3    # set an exact version
./scripts/version.sh -i                 # 4.0.0-beta.2 -> 4.0.0-beta.3, or 4.0.0 -> 4.0.1
./scripts/version.sh -i -p              # 4.0.0-beta.2 -> 4.0.0
./scripts/version.sh -c                 # check all four literals agree
./scripts/test_version.sh               # tests for version.sh and validate_version.sh
```

`version.sh` rejects anything outside that format, and fails if a file was not updated.

`fastlane version_bump` is not an alternative: fastlane was deleted on this line.

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

1. On a branch, run `./scripts/version.sh -s <version>` and update `ChangeLog.md`. Merge that PR.
   `version-bump.yml` does the same bump from CI, but it pushes straight to the branch it ran on.
2. Optionally, check the build without publishing:
   `gh workflow run release.yml --ref <branch> -f version=<version> -f dry_run=true`.
3. Release: `gh workflow run release.yml --ref <branch> -f version=<version>`.

`release.yml` starts with `scripts/validate_version.sh`, which fails the run unless `<version>`
equals the version on the selected branch, all four literals agree, and the tag does not exist yet.
It then builds the four XCFrameworks, creates the tag and a GitHub release on the workflow commit
(marked as a pre-release when the version has a suffix), uploads the assets and triggers the SPM
repo. CocoaPods trunk push is still a TODO in the workflow.

`ChangeLog.md` is maintained by hand. `sync-readme-changelog.yml` does not touch it: on a
published release it pushes the release body to ReadMe.io and announces in Slack.
