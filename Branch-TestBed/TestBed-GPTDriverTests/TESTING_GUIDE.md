# Testing Guide — TestBed-GPTDriverTests

A practical manual for working on the MobileBoost hybrid test suite for the iOS Branch SDK TestBed. Read this before writing a new test.

## Philosophy: deterministic first, AI second

Every test in this target falls into one of three modes. Pick the mode that matches the flow; do not reach for AI when plain XCUITest would do.

| Use XCUITest when… | Use GPTDriver AI when… |
|---|---|
| An element has an `accessibilityIdentifier` in `TestBedIdentifiers.h` | Validating visual output (QR code image, chart, share sheet preview) |
| The action is a simple tap / type / swipe | Extracting data from a modal (`driver.extract`) |
| The assertion is exact text or state | Navigating across apps (Safari ↔ TestBed, Settings ↔ TestBed) |
| The flow is stable | Asserting semantic correctness (`driver.assert`) |
| Speed & determinism matter (sub-second feedback loops) | A step is flaky or the UI is undergoing change |

**Rule of thumb:** if you can write the test in 5 lines of XCUITest, do that. Every call to the AI driver costs cloud round-trip time and incurs MobileBoost usage.

## The three modes in this repo

- **Deterministic** (`Deterministic/`) — 100% XCUITest. No `driver.*` calls except session lifecycle (handled by `BaseGptDriverTest.tearDownWithError`).
- **Hybrid** (`Hybrid/`) — XCUITest for the actions the storyboard identifiers can express, AI for validations XCTest cannot.
- **AI** (`AI/`) — 100% GPTDriver. No `accessibilityIdentifier` or `XCUIElement` queries. The agent reads the screen and acts autonomously.

The same flow should typically live in all three modes as separate test classes, giving you structural coverage (Deterministic), UX coverage (Hybrid), and resilience coverage (AI).

## Writing a new test

1. **Subclass `BaseGptDriverTest`.**
2. **Prefer identifiers from `TestBedIdentifiers.h`.** They are exposed to Swift through the bridging header. If the control you need has no identifier, add one in `TestBedIdentifiers.h/.m` and `Main.storyboard` — those changes ship in a separate PR under `Branch-TestBed`, not in the test target.
3. **Reuse the base helpers:**
   - `generateBranchLink(timeout:)` — taps Create Branch Link and polls the text field until a real HTTPS URL appears.
   - `waitForLinkInField(_:timeout:)` — raw polling helper.
   - `TestScrollHelpers.scrollUntilVisible(_:in:)` — scrolls a container until a below-the-fold element is hittable.
4. **Use `try driver.*` for AI calls.** All GPTDriver methods throw. In tearDown we use `try?` on `setSessionSucceeded` / `setSessionFailed` because those shouldn't hide real test failures.
5. **Do NOT call `driver.setSessionSucceeded()` inside your test methods.** Session status is set automatically by `tearDownWithError` based on `testRun.failureCount`. Calling it manually in a passing branch can create false positives on failed runs.
6. **Check lint before committing:** `swiftformat TestBed-GPTDriverTests/` and `swiftlint lint --quiet TestBed-GPTDriverTests/` should both report zero warnings.

## Minimal test skeleton

```swift
import XCTest

final class MyFeatureHybridTest: BaseGptDriverTest {
    func testFeature_behavesAsExpected() throws {
        // DETERMINISTIC: drive the UI with identifiers
        let button = app.buttons[kTestBedBtnMyFeature]
        TestScrollHelpers.scrollUntilVisible(button, in: app)
        button.tap()

        // DETERMINISTIC: cheap structural assertion
        XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: 5))

        // AI: semantic / multi-condition validation
        try driver.assertBulk([
            "A confirmation message is visible to the user",
            "The message does not contain the word 'Error'"
        ])
    }
}
```

## Deep link tests — launch argument hook

`DeepLinkColdOpenHybridTest`, `DeepLinkWarmOpenHybridTest`, and `BrowserExperienceHybridTest` simulate Safari → app Universal Link handoff via a test-only hook in `Branch-TestBed/Branch-TestBed/AppDelegate.m`:

```objc
#if DEBUG
NSString *testDeepLinkURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"testDeepLinkURL"];
if (testDeepLinkURL.length > 0) {
    NSURL *url = [NSURL URLWithString:testDeepLinkURL];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSUserActivity *activity = [[NSUserActivity alloc]
            initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = url;
        [self application:application
             continueUserActivity:activity
               restorationHandler:^(NSArray * _Nullable r) {}];
    });
}
#endif
```

The hook reads a `-testDeepLinkURL <url>` launch argument and, if present, constructs an `NSUserActivity` of type `NSUserActivityTypeBrowsingWeb` and calls `application:continueUserActivity:` after a 1.5s delay (enough for `Branch.initSessionWithLaunchOptions` to register its handler). The Branch SDK resolution path is **byte-for-byte identical** to a real Safari Universal Link handoff — the SDK has no way to tell the synthetic delivery apart from the real thing.

**Why this is necessary on simulator:** Universal Link handoff via Safari requires the app to be code-signed with the `com.apple.developer.associated-domains` entitlement embedded in the signature. Tests run unsigned via `CODE_SIGNING_ALLOWED=NO`, so the `swcutil` daemon never associates the app with `bnctestbed.test-app.link` and Safari does not hand off. The hook bypasses Safari entirely while still exercising the full SDK code path.

**Safety:** the hook is wrapped in `#if DEBUG` so it never ships in Release builds, and it requires an explicit launch argument — no production code path can accidentally trigger it.

**Test flow** (all 3 tests follow this pattern):

1. Generate a real Branch link via the existing TestBed UI and extract the URL via `driver.extract`.
2. `app.terminate()` (cold) or `XCUIDevice.shared.press(.home)` (warm).
3. Set `app.launchArguments += ["-testDeepLinkURL", generatedUrl]` and call `app.launch()` again.
4. Wait ~5 seconds for the AppDelegate hook to fire and Branch SDK to resolve the link.
5. Verify Branch's `handleDeepLinkParams` auto-pushed `LogOutputViewController` (signaled by the navigation bar titled "Logs") and that the visible JSON contains expected metadata keys (`~channel`, `~feature`, `+match_guaranteed`, `+clicked_branch_link`, etc.).

## StoreKit / IAP tests

`EventLoggingHybridTest` covers both real IAP purchases and subscriptions. These flows present a StoreKit sheet driven by `TestStoreKitConfig.storekit` (already in the TestBed bundle). The scheme must be configured to load the storekit config when the test target launches — this is set in `TestBed-GPTDriverTests.xcscheme` by default.

Each event test gives the AI a chance to dismiss the StoreKit sheet via `try? driver.execute("Dismiss any StoreKit dialog if one is visible")` before re-asserting that the main screen is visible.

## API key resolution

`BaseGptDriverTest.resolveApiKey()` tries, in order:

1. `MOBILEBOOST_API_KEY` process environment variable (set by `xcodebuild MOBILEBOOST_API_KEY=xxx`).
2. `MOBILEBOOST_API_KEY` in the test bundle's Info.plist, which Xcode substitutes at build time from `Config/MobileBoost.xcconfig` (which optionally `#include?`s `MobileBoost.local.xcconfig`).
3. Empty string → `precondition` failure with a clear message pointing at the example file.

The real `MobileBoost.local.xcconfig` is gitignored by the `*.local.xcconfig` rule in the repo root `.gitignore`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `precondition failed: MOBILEBOOST_API_KEY not configured` | No `MobileBoost.local.xcconfig` and no env var | Copy the template and fill in your key, or `export MOBILEBOOST_API_KEY=…` before `xcodebuild` |
| Linker error `_kTestBedBtn…` undefined | `TestBedIdentifiers.m` not linked into the test target | Verify it's listed in Compile Sources of `TestBed-GPTDriverTests`; the xcodeproj gem script adds it automatically |
| `module map file 'ObjCExceptionCatcher.modulemap' not found` | Building with `-target` instead of `-scheme` | Always use `-scheme TestBed-GPTDriverTests` for builds; SPM dependency resolution requires a scheme |
| Deep link test never sees the LogOutput screen | The AppDelegate `#if DEBUG` hook is missing or the launch argument is misspelled | Verify `Branch-TestBed/AppDelegate.m` still has the `testDeepLinkURL` block, and check that the test passes `["-testDeepLinkURL", url]` (exactly that key, dash-prefixed) |
| SwiftFormat and SwiftLint disagree on trailing commas | Default-config mismatch between the two tools | This directory has a local `.swiftformat` that disables `trailingCommas` — if you see the conflict, that file is the fix |
| Tests run but session shows `failed` on dashboard even though `XCTAssert` passed | Forgot that session status is auto-set in tearDown | Remove any manual `driver.setSessionSucceeded()` calls from test bodies — they're redundant and fragile |

## Pre-merge checklist for new tests

Before declaring a new test ready for review:

- [ ] Consistent test class name (`XxxHybridTest` / `XxxDeterministicTest` / `XxxAITest`).
- [ ] Each `func test…()` method covers a distinct scenario with a descriptive name.
- [ ] Tagged `Release` or `Smoke` via the appropriate test plan in `TestBed-GPTDriverTests.xcscheme`.
- [ ] A single Branch SDK API is exercised per class where possible (Link creation, Event, ReferringParams, …).
- [ ] Platform-specific quirks are documented in the test class header comment.
- [ ] New identifiers (if any) added to `TestBedIdentifiers.h/.m` AND `Main.storyboard`.
- [ ] `swiftformat` + `swiftlint` are green.
- [ ] `xcodebuild build-for-testing -scheme TestBed-GPTDriverTests` succeeds.
- [ ] Flaky steps are flagged with code comments noting the known limitation.

## Scope of what this target does NOT cover

- **Unit tests for the SDK itself.** Those live in `Branch-SDK-Tests` and `Branch-SDK-Unhosted-Tests` under the same Xcode project. This target is strictly E2E on the TestBed app.
- **The legacy `Branch-TestBed-UITests` suite.** That bundle ships with Obj-C XCUITests that predate GPTDriver and remain as fast local smoke tests. Do not migrate them here — this target is the dedicated AI-assisted hybrid test layer and should not absorb the legacy smoke suite.
- **Device testing.** Everything here assumes simulator. Physical-device runs require code signing + provisioning work that is out of scope.
- **CI integration.** The existing `.github/workflows/gptdriverautomation.yml` workflow handles the Path-A AI-only JSON suites under `gptdriver/` on `Release-*` branches. A future PR will add a `build-for-testing` job to run this target as well.

## AI-only JSON suites ↔ hybrid class mapping

The repo already ships 27 AI-only JSON suites under `gptdriver/` that exercise the TestBed via Appium + MobileBoost cloud. Each hybrid class in this target has a rough counterpart among those JSONs — the JSON describes the same scenario in narrative form for the AI-only runner. A non-exhaustive mapping:

| Hybrid test class | AI-only JSON suite(s) |
|---|---|
| `LinkCreationHybridTest` | `create-branch-link.json`, `create-deep-link.json` |
| `QRCodeHybridTest` | `qr-code-generation.json`, `qr-code-test.json` |
| `EventLoggingHybridTest` | `event-commerce.json`, `event-content.json`, `event-lifecycle.json` |
| `ReferringParamsHybridTest` | `first-referring-params.json`, `latest-referring-params.json` |
| `DeepLinkColdOpenHybridTest` | `cold-open-universal-link.json`, `universal-link-cold-open-*.json`, `uri-scheme-cold-start-*.json` |
| `DeepLinkWarmOpenHybridTest` | `warm-open-via-universal-link.json`, `uri-scheme-warm-open-*.json` |
| `UserIdentityHybridTest` | `set-user-id.json`, `simulate-logout.json` |
| `ShareLinkHybridTest` | `share-sheet-test.json` |
| `TrackingControlHybridTest` | `tracking-toggle.json` |
| `ConsumerProtectionHybridTest` | `set-dma-params.json` |

The two paths coexist: the AI-only suites run on MobileBoost cloud via Appium; the hybrid tests run locally or in CI via `xcodebuild test`. Both report to the same MobileBoost dashboard.
