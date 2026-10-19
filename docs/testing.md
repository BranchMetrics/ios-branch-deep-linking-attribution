# Testing and CI (master, 3.x)

## Where tests live

Tests are under `Branch-TestBed/`, not next to `Sources/`.

| Directory | What it is |
| --- | --- |
| `Branch-TestBed/Branch-SDK-Tests/` | the main suite (~46 files), hosted in the TestBed app |
| `Branch-TestBed/Branch-SDK-Unhosted-Tests/` | the few tests that must run without an app host |
| `Branch-TestBed/Reflection_ODM_Tests/` | ODM reflection tests, own scheme and test plan |
| `Branch-TestBed/TestBed-GPTDriverTests/` | MobileBoost/GPTDriver E2E, plans `Smoke`, `Release`, `L1Validation` |

`Branch-TestBed-CI.xctestplan` is the PR gate's plan and it runs **only the `Branch-SDK-Tests`
target**. `Reflection_ODM_Tests` is listed in the plan but `"enabled": false`. A new test target
that is not added to that plan will never run in CI.

## Running them

```bash
bundle install                       # Ruby 2.7 + Bundler
bundle exec fastlane unit_tests      # exactly what the PR gate runs

# The same tests without fastlane
xcodebuild test -project Branch-TestBed/Branch-TestBed.xcodeproj \
  -scheme Branch-TestBed-CI \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest"

# A single class
xcodebuild test ... -only-testing:Branch-SDK-Tests/BNCRequestFactoryTests

# Unit plus integration (network-touching). Manual, not run on PRs.
bundle exec fastlane integration_tests
```

`unit_tests` runs `scan` on the `Branch-TestBed-CI` scheme and then `slather` for coverage.
`integration_tests` runs the `Branch-TestBed` scheme, whose plan includes the network tests.

## CI gates

| Workflow | Role |
| --- | --- |
| `verify.yml` | the PR gate. `fastlane unit_tests` on `macos-15`, uploads results and Codecov coverage |
| `layer1-logger-tests.yml` | Layer 1 wire validation, see below |
| `pre-release-qa.yml` / `post-release-qa.yml` | exercise CocoaPods, Carthage, SPM and XCFramework for iOS and tvOS against `SDKIntegrationTestApps/` |
| `release.yml` | builds and signs the XCFrameworks with checksums. Gated by a `static-analysis` job running `xcodebuild analyze` |
| `integration-tests.yml` | manual only: `gh workflow run integration-tests.yml` |

**There is no style linter** (no SwiftLint, no OCLint) anywhere in this repo. Code that merely
compiles is not necessarily release-clean: `release.yml` runs `xcodebuild analyze` and
`scripts/prep_release.sh` runs `pod lib lint`.

**Xcode pinning.** `layer1-logger-tests.yml` is the only workflow that pins Xcode, via
`setup-xcode@v1` on `macos-15`; the pin currently reads `^16.4`. It is the only pinned one: `verify.yml` also runs on
`macos-15` but takes the runner image's default Xcode, and every other workflow is
`macos-latest` and unpinned.

## Layer 1 wire validation

`layer1-logger-tests.yml` builds the TestBed, runs `L1WireValidationTest` on an iPhone 16
simulator, captures `branchlogs.txt`, and asserts that required device and SDK fields are
actually on the wire via `scripts/validate_l1_logs.py`. It triggers only on changes to
`Sources/**`, `Branch-TestBed/**`, or the validator itself, and it runs on PRs into `master`
and into `4.0.0-beta.*`.

```bash
python3 scripts/validate_l1_logs.py path/to/branchlogs.txt
python3 -m unittest scripts.test_validate_l1_logs -v   # validator self-tests
```

The validator's self-test runs **before** the real validation on purpose: a broken validator
would otherwise show up as a false PASS.

## Writing tests here

- Pin `BNCURLFilter`'s pattern list in any test that asserts on URL filtering. It self-updates
  from the server after init, so the runtime list can differ from the compiled-in default.
- `BNCPreferenceHelper` with `useStorage == NO` keeps state in memory. Use it rather than
  writing the real `BNCPreferences` archive.
- `BNCServerInterface` is injectable through the `Branch` designated initializer. Assert on what
  reaches the interface, not on what was enqueued.
- Justify a new test in the PR body: name the failure it catches that no existing test catches.
  If the answer is "the same path from a different angle", drop it.
