#!/usr/bin/env bash
#
# L1 instrumentation runner for the iOS Branch SDK TestBed.
#
# Invoked from .github/workflows/layer1-logger-tests.yml after the workflow
# has already built the TestBed app via `xcodebuild build-for-testing`. This
# script:
#   1. Identifies / boots a target simulator.
#   2. Runs the L1Validation test plan via `xcodebuild test-without-building`.
#   3. Pulls branchlogs.txt out of the simulator's TestBed app sandbox so
#      the Python validator (validate_l1_logs.py) can parse it.
#
# Required env / inputs:
#   DERIVED_DATA_DIR     - path to the build-for-testing output (default ./DerivedData)
#   SIM_NAME             - simulator device name (default "iPhone 16")
#   SIM_OS               - simulator iOS version, "latest" or explicit (default "latest")
#   PROJECT_PATH         - path to .xcodeproj (default Branch-TestBed/Branch-TestBed.xcodeproj)
#   SCHEME               - scheme name (default TestBed-GPTDriverTests)
#   ONLY_TESTING         - xcodebuild -only-testing selector (default
#                          TestBed-GPTDriverTests/L1WireValidationTest)
#   BUNDLE_ID            - TestBed app bundle id (default io.branch.sdk.Branch-TestBed)
#   OUTPUT_LOG           - destination for the pulled file (default branchlogs.txt)
#
# Notes:
#   * We deliberately uninstall the TestBed bundle before running so the SDK
#     emits a fresh /v1/install. If we skip this, a cached randomized_device
#     _token would route the request to /v1/open and the validator would
#     fail to assert the mandatory /v1/install endpoint.
#   * `xcodebuild test-without-building` exits non-zero on test failure; we
#     trap to ensure we still attempt to pull the log file for diagnostics.

set -euo pipefail

DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-./DerivedData}"
SIM_NAME="${SIM_NAME:-iPhone 16}"
SIM_OS="${SIM_OS:-latest}"
PROJECT_PATH="${PROJECT_PATH:-Branch-TestBed/Branch-TestBed.xcodeproj}"
SCHEME="${SCHEME:-TestBed-GPTDriverTests}"
ONLY_TESTING="${ONLY_TESTING:-TestBed-GPTDriverTests/L1WireValidationTest}"
BUNDLE_ID="${BUNDLE_ID:-io.branch.sdk.Branch-TestBed}"
OUTPUT_LOG="${OUTPUT_LOG:-branchlogs.txt}"

echo "==> L1 instrumentation starting"
echo "    Derived data dir : $DERIVED_DATA_DIR"
echo "    Simulator        : $SIM_NAME ($SIM_OS)"
echo "    Scheme           : $SCHEME"
echo "    Only testing     : $ONLY_TESTING"
echo "    Bundle id        : $BUNDLE_ID"

# Boot the simulator first so subsequent simctl commands target an awake
# device. `simctl boot` is idempotent (no-op if already booted).
echo "==> Booting simulator '$SIM_NAME'..."
# `simctl list devices` expects `[available]` before the optional search
# term, not after. Putting `$SIM_NAME` first causes `available` to be
# treated as part of the name filter, and on some Xcode versions the JSON
# silently returns no matches. Drop the bash-level name filter and let
# the Python below do the name match — the JSON already only contains
# available devices.
SIM_UDID=$(xcrun simctl list devices available -j \
    | python3 -c '
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data["devices"].items():
    for d in devices:
        if d.get("isAvailable") and d.get("name") == sys.argv[1]:
            print(d["udid"])
            sys.exit(0)
sys.exit(1)
' "$SIM_NAME") || true

if [ -z "$SIM_UDID" ]; then
    echo "ERROR: no available simulator named '$SIM_NAME'. Listing available:"
    xcrun simctl list devices available
    exit 1
fi
echo "    UDID: $SIM_UDID"

xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b

# Wipe any prior install so the SDK fires /v1/install (not /v1/open).
echo "==> Uninstalling any prior TestBed install..."
xcrun simctl uninstall "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true

# Run the L1 test. We use test-without-building because the workflow's
# previous step already produced the .xctestrun in DerivedData. We do
# NOT pass -testPlan to avoid having to wire L1Validation.xctestplan
# into the shared scheme (the scheme has a separate WIP edit in flight).
# `-only-testing` filters to just the L1WireValidationTest class against
# the scheme's default test plan.
echo "==> Running '$ONLY_TESTING'..."
TEST_EXIT_CODE=0
xcodebuild test-without-building \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -only-testing:"$ONLY_TESTING" \
    -destination "platform=iOS Simulator,id=$SIM_UDID" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" || TEST_EXIT_CODE=$?

# Even if tests failed, attempt to pull the log file so the validator (and
# upload-artifact step) can surface a useful failure reason.
echo "==> Locating TestBed app container..."
APP_DATA=""
if APP_DATA=$(xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE_ID" data 2>/dev/null); then
    echo "    Container: $APP_DATA"
    LOG_SOURCE="$APP_DATA/Documents/branchlogs.txt"
    if [ -f "$LOG_SOURCE" ]; then
        cp "$LOG_SOURCE" "$OUTPUT_LOG"
        echo "==> Pulled $OUTPUT_LOG ($(wc -l < "$OUTPUT_LOG" | tr -d ' ') lines)"
    else
        echo "WARN: $LOG_SOURCE does not exist; SDK may not have written any log."
        : > "$OUTPUT_LOG"
    fi
else
    echo "WARN: could not resolve app container for $BUNDLE_ID (was the app installed?)"
    : > "$OUTPUT_LOG"
fi

if [ "$TEST_EXIT_CODE" -ne 0 ]; then
    echo "==> Test plan reported exit code $TEST_EXIT_CODE"
    exit "$TEST_EXIT_CODE"
fi

echo "==> L1 instrumentation complete"
