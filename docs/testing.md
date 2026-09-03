# Testing and CI (4.0.0-beta)

## Where tests live

Unit tests are a first-class `BranchSDKTests/` target inside `BranchSDK.xcodeproj`, with its own
`BranchSDKTests/BranchSDKTests.xctestplan`. This is the main structural difference from `master`,
where tests are hosted under `Branch-TestBed/`.

**A test added to `Branch-TestBed/Branch-SDK-Tests/` will not run in CI on this line.** Put new
unit tests in `BranchSDKTests/`.

`Branch-TestBed/` still exists and still holds the GPTDriver E2E suite
(`Branch-TestBed/TestBed-GPTDriverTests/`, plans `Smoke`, `Release`, `L1Validation`).

## Running them

```bash
./scripts/getSimulator
xcodebuild test -project BranchSDK.xcodeproj -scheme BranchSDKTests \
  -destination "platform=iOS Simulator,name=$(cat ./iphoneSim),OS=latest" \
  -testPlan BranchSDKTests
```

A single class:

```bash
xcodebuild test ... -only-testing:BranchSDKTests/BNCRequestFactoryTests
```

There is no fastlane and no `Gemfile` on this branch, and no style linter.

## Which CI gates are real

| Workflow | State |
| --- | --- |
| `verify.yml` | **works.** Runs the `xcodebuild test` above on `macos-15`. The `push:` trigger has no branch filter, so it fires for any pushed branch |
| `layer1-logger-tests.yml` | **works.** The L1 wire gate, ported to this line so it exists in the PR merge tree. Triggers on push and PR against `4.0.0-beta.*` |
| `gptdriver-e2e.yml` | **works, two jobs.** The deterministic half runs on every push and PR on this line. The full suite drives the MobileBoost device farm, needs `MOBILEBOOST_API_KEY`, and runs only on manual dispatch or a push to `Release-*` |
| `version-bump.yml` | **dead.** Shells out to `bundle exec fastlane`, which does not exist here |
| `integration-tests.yml` | **dead.** Same reason |
| `release.yml` | **dead.** Same reason |

The last three do not verify anything on this branch until they are rewritten for it. A passing
run from one of them is not a signal.

## Layer 1 wire validation

Builds the TestBed, runs the wire test, captures `branchlogs.txt`, and asserts that required
device and SDK fields are actually on the wire.

```bash
python3 scripts/validate_l1_logs.py path/to/branchlogs.txt
python3 -m unittest scripts.test_validate_l1_logs -v   # validator self-tests
```

The validator's self-test runs **before** the real validation on purpose: a broken validator
would otherwise show up as a false PASS.

## Writing tests here

- **Assert on the server interface, not on enqueue.** Attribution level `NONE` drops a request
  inside `BNCServerRequestOperation` before the network layer, so an enqueue that "succeeds"
  proves nothing about what was sent.
- **Never assert on session state or a session ID.** Neither exists. The portable definition of
  "session established" is both randomized tokens persisted plus the open callback fired.
- **Pin `BNCURLFilter`'s pattern list** in any test that asserts on URL filtering. It self-updates
  from the server after init.
- **A link-resolving open is two requests**, `/v3/deeplink` then `/v3/events/open`. A test that
  expects one will pass or fail for the wrong reason.
- Justify a new test in the PR body: name the failure it catches that no existing test catches.
