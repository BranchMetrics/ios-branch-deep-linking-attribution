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
#   UNINSTALL_FIRST      - 1 (default) wipes the app before running, so the SDK
#                          treats the launch as a first install. 0 leaves the
#                          prior install in place, which is the only way to
#                          drive a launch on an already-installed device —
#                          C1 and C3 share a driver and differ only in this.
#
# Notes:
#   * The uninstall is what makes a run a first install. On this line that is
#     not a separate endpoint: install and open both post to /v3/events/open
#     and are told apart by the install one carrying no randomized_bundle_token.
#     Set UNINSTALL_FIRST=0 to keep the prior install and drive the other case.
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
UNINSTALL_FIRST="${UNINSTALL_FIRST:-1}"

echo "==> L1 instrumentation starting"
echo "    Derived data dir : $DERIVED_DATA_DIR"
echo "    Simulator        : $SIM_NAME ($SIM_OS)"
echo "    Scheme           : $SCHEME"
echo "    Only testing     : $ONLY_TESTING"
echo "    Bundle id        : $BUNDLE_ID"
echo "    Uninstall first  : $UNINSTALL_FIRST"

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

if [ "$UNINSTALL_FIRST" = "1" ]; then
    echo "==> Uninstalling any prior TestBed install..."
    xcrun simctl uninstall "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
else
    echo "==> Keeping any prior install (UNINSTALL_FIRST=0)"
fi

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
