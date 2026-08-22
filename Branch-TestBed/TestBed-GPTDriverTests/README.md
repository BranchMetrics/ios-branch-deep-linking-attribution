# TestBed-GPTDriverTests

MobileBoost / GPTDriver hybrid test target for the Branch iOS SDK TestBed.

The target follows a hybrid philosophy: **deterministic XCUITest first, AI-assisted validation only when XCTest matchers cannot express the intent**.

## What is this?

A UI Testing Bundle (`TestBed-GPTDriverTests.xctest`) that drives the Branch TestBed app through end-to-end scenarios and reports results to the MobileBoost cloud dashboard. Each test case:

1. Performs deterministic steps via `XCUIApplication` — taps buttons by `accessibilityIdentifier`, reads text fields, asserts with `XCTAssert*`.
2. When the assertion is visual, semantic, or multi-conditional, hands off to the [`gptd-swift`](https://github.com/MobileBoostHQ/gptd-swift) SDK — `driver.execute`, `driver.assert`, `driver.assertBulk`, `driver.extract`, `driver.checkBulk`.
3. Reports `setSessionSucceeded` / `setSessionFailed` to the MobileBoost dashboard automatically via `BaseGptDriverTest.tearDownWithError`.

## Quick start

```bash
# 1. Copy the secret template
cd Branch-TestBed/TestBed-GPTDriverTests/Config
cp MobileBoost.local.xcconfig.example MobileBoost.local.xcconfig

# 2. Paste your MobileBoost API key into the new file
#    (the file is gitignored — your key never leaves your machine)

# 3. Run the full suite
cd ../../..
xcodebuild test \
  -project Branch-TestBed/Branch-TestBed.xcodeproj \
  -scheme TestBed-GPTDriverTests \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
  CODE_SIGNING_ALLOWED=NO
```

To run a single class:

```bash
xcodebuild test \
  -project Branch-TestBed/Branch-TestBed.xcodeproj \
  -scheme TestBed-GPTDriverTests \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
  -only-testing:TestBed-GPTDriverTests/LinkCreationHybridTest \
  CODE_SIGNING_ALLOWED=NO
```

Each run opens a session on the MobileBoost dashboard with the `sessionURL` available via `driver.sessionURL` inside the test.

## Layout

```
TestBed-GPTDriverTests/
├── BaseGptDriverTest.swift         — base class, driver init, link helpers
├── TestScrollHelpers.swift         — scroll-until-visible helper for below-the-fold buttons
├── TestBed-GPTDriverTests-Bridging-Header.h
│                                   — imports TestBedIdentifiers.h so Swift tests see the
│                                     same accessibilityIdentifier string constants as the
│                                     Obj-C storyboard
├── Info.plist                      — declares MOBILEBOOST_API_KEY = $(MOBILEBOOST_API_KEY)
├── Config/
│   ├── MobileBoost.xcconfig        — committed, #include? of MobileBoost.local.xcconfig
│   ├── MobileBoost.local.xcconfig  — GITIGNORED, your real key
│   └── MobileBoost.local.xcconfig.example
├── Deterministic/                  — 100% XCUITest, no AI
│   └── LinkCreationDeterministicTest.swift
├── Hybrid/                         — XCUITest actions + AI validation
│   ├── LinkCreationHybridTest.swift
│   ├── QRCodeHybridTest.swift
│   ├── ShareLinkHybridTest.swift
│   ├── SessionAndLogsHybridTest.swift
│   ├── UserIdentityHybridTest.swift
│   ├── EventLoggingHybridTest.swift
│   ├── DeepLinkColdOpenHybridTest.swift
│   ├── DeepLinkWarmOpenHybridTest.swift
│   ├── BrowserExperienceHybridTest.swift
│   ├── NotificationHybridTest.swift         ← XCTSkip until iOS TestBed adds button
│   ├── TrackingControlHybridTest.swift
│   ├── ConsumerProtectionHybridTest.swift
│   ├── ReferringParamsHybridTest.swift
│   └── PluginNotifyHybridTest.swift         ← XCTSkip until iOS TestBed adds button
├── AI/                             — 100% AI-driven, no identifiers
│   └── LinkCreationAITest.swift
├── TestPlans/
│   ├── Smoke.xctestplan            — fast dev-loop subset (~37s)
│   └── Release.xctestplan          — full suite (~15m), default in scheme
└── scripts/
    └── format-test-results.sh      — parse xcodebuild log into markdown row
```

## Dependencies

- Swift Package: `gptd-swift` (≥ 1.9.1, up to next major). Declared in the parent `Branch-TestBed.xcodeproj`.
- iOS 14.0+ (the minimum platform declared by `gptd-swift`). The host app `Branch-TestBed` still targets iOS 12, so running these tests requires a simulator with iOS ≥ 14.
- Runs on simulator only (code signing disabled).

## Secret management

The API key is resolved in this order inside `BaseGptDriverTest.resolveApiKey()`:

1. Process environment variable `MOBILEBOOST_API_KEY` (set by `xcodebuild MOBILEBOOST_API_KEY=xxx`)
2. `MOBILEBOOST_API_KEY` in the test bundle's `Info.plist`, which Xcode substitutes at build time from `Config/MobileBoost.xcconfig` (which optionally `#include?`s `MobileBoost.local.xcconfig`)
3. Empty → `precondition` failure with a clear message pointing at the example file

Copy [`Config/MobileBoost.local.xcconfig.example`](./Config/MobileBoost.local.xcconfig.example) to `Config/MobileBoost.local.xcconfig` and paste your key. The example file is committed; the real file is gitignored by the `*.local.xcconfig` rule in the repo root `.gitignore`.

## Test Plans

Two Xcode Test Plans live in `TestPlans/` and are wired into the `TestBed-GPTDriverTests` scheme:

| Plan | Tests | Wall time | When to run |
|---|---|---|---|
| `Smoke.xctestplan` | 5 cherry-picked fast tests | ~37s | Every PR, tight dev loop |
| `Release.xctestplan` | Full suite (all 16 classes) | ~15m | Before merging to release branch; default plan in the scheme |

To run a specific plan from the command line:

```bash
xcodebuild test \
  -project Branch-TestBed/Branch-TestBed.xcodeproj \
  -scheme TestBed-GPTDriverTests \
  -testPlan Smoke \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
  CODE_SIGNING_ALLOWED=NO
```

## Pending TestBed features

2 of the 16 tests are placeholders (`XCTSkip`) pending TestBed feature additions:

| Test | Required TestBed feature |
|---|---|
| `NotificationHybridTest` | A "Send Notification" button + IBAction that schedules a local `UNNotificationRequest` carrying a Branch link |
| `PluginNotifyHybridTest` | A "Simulate Plugin Notify Init" button + IBAction that calls `[[Branch getInstance] notifyNativeToInit]` |

Both files contain header comments with the exact changes required to enable them.

## See also

- [`TESTING_GUIDE.md`](./TESTING_GUIDE.md) — writing new tests, philosophy, troubleshooting.
