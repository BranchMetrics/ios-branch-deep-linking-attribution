# TestBed-GPTDriverTests

Keyless wire-validation harness for the Branch iOS SDK TestBed.

A UI Testing Bundle that drives the `Branch-TestBed` host app with plain XCUITest so the SDK
sends real requests. The SDK's advanced log callback in the TestBed writes every outbound request
to `branchlogs.txt` in the app's Documents directory, and the scripts in `scripts/` pull that file
out of the simulator and validate it. No test here needs a credential or any service beyond the
Branch API the SDK itself calls.

The target name is historical and will be renamed separately.

## Tests

All five live in `Deterministic/`, one class per capture, because the TestBed deletes
`branchlogs.txt` on every launch and a second launch in the same run would overwrite the first
capture.

| Class | What it drives |
| --- | --- |
| `L1WireValidationTest` | A plain launch, waiting for the SDK to send its install request. |
| `ColdLinkWireValidationTest` | A Universal Link delivered into a freshly launched process through the AppDelegate's `-testDeepLinkURL` hook. The delivery is synthetic; real OS handoff needs a signed build. |
| `ColdLinkInstalledWireValidationTest` | The same link on a device that already has the app. The test performs its own install first, then relaunches and captures the second launch. |
| `DeepLinkWireValidationTest` | Taps "Request DeepLink" so `/v3/deeplink` appears in the capture. |
| `EventAndLinkWireCaptureTest` | Taps the link-creation control and the event controls with fixed pauses, so an external log capture can attribute each request to its control. It asserts only that each control is hittable. |

`TestScrollHelpers.swift` holds the scroll-until-visible helpers the last two use.

## Running

`scripts/run_l1_instrumented.sh` runs one class per invocation with `xcodebuild
test-without-building -only-testing:<selector>` against an existing `build-for-testing` output,
then copies `branchlogs.txt` out of the simulator for `scripts/validate_l1_logs.py`. It defaults
to `L1WireValidationTest`; set `ONLY_TESTING` to pick another class and `OUTPUT_LOG` to keep each
capture separate.

```bash
./scripts/getSimulator
xcodebuild build-for-testing \
  -project Branch-TestBed/Branch-TestBed.xcodeproj \
  -scheme TestBed-GPTDriverTests \
  -derivedDataPath ./DerivedData \
  -destination "platform=iOS Simulator,name=$(cat ./iphoneSim),OS=latest" \
  CODE_SIGNING_ALLOWED=NO

SIM_NAME="$(cat ./iphoneSim)" ./scripts/run_l1_instrumented.sh
python3 scripts/validate_l1_logs.py branchlogs.txt --scenario install
```

`.github/workflows/layer1-logger-tests.yml` runs the install, cold first-install and cold
installed scenarios this way on every push and pull request against `4.0.0-beta.*` that touches
the SDK sources, the TestBed or the L1 scripts. `scripts/README.md` documents the scenarios and
their contracts.

The scheme runs the target's tests directly, so `-only-testing` selects any class above.
`TestPlans/L1Validation.xctestplan`, which selects only the install test, is kept but is not
referenced by the scheme.
