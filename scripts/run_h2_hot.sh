#!/usr/bin/env bash
#
# hot_uriScheme / hot_https_foreground (and warm_uriScheme) driver for the iOS Branch SDK TestBed.
#
# Launches the TestBed, snapshots branchlogs.txt once the launch settles, opens
# a scheme URL into the foregrounded app with `simctl openurl`, and snapshots
# again. Validate with:
#
#   validate_l1_logs.py "$OUTPUT_DIR/wire-hot_uriScheme.post.txt" \
#       --scenario hot_uriScheme --pre "$OUTPUT_DIR/wire-hot_uriScheme.pre.txt"
#
# Required env:
#   H2_EXPECT_RUNTIME  - runtime the device must be on, for example iOS-18-5
# Optional env:
#   DERIVED_DATA_DIR   - build-for-testing output (default ./DerivedData)
#   SIM_NAME           - simulator device name (default "iPhone 16 Plus")
#   SIM_UDID           - select this device instead of matching SIM_NAME
#   BUNDLE_ID          - TestBed bundle id (default io.branch.sdk.Branch-TestBed)
#   OUTPUT_DIR         - where the snapshots go (default .)
#   SETTLE_S           - seconds the log must stay unchanged (default 10)
#   SETTLE_MAX_S       - give up settling after this many seconds (default 120)
#   OPENURL_MAX_S      - retry budget for LaunchServices error 115 (default 120)
#   HOT_SCENARIO       - hot_uriScheme or hot_https_foreground (default hot_uriScheme)
#   H2_URL             - URL to deliver (default branchtest://open?scenario=H2)
#   WARM               - 1 backgrounds the app with Preferences before the pre
#                        snapshot (warm_uriScheme)
#   CAPTURE_NAME       - snapshot file prefix (default wire-hot_uriScheme)

set -euo pipefail

: "${H2_EXPECT_RUNTIME:?H2_EXPECT_RUNTIME is required, for example iOS-18-5}"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-./DerivedData}"
SIM_NAME="${SIM_NAME:-iPhone 16 Plus}"
SIM_UDID="${SIM_UDID:-}"
BUNDLE_ID="${BUNDLE_ID:-io.branch.sdk.Branch-TestBed}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"
SETTLE_S="${SETTLE_S:-10}"
SETTLE_MAX_S="${SETTLE_MAX_S:-120}"
OPENURL_MAX_S="${OPENURL_MAX_S:-120}"
H2_URL="${H2_URL:-branchtest://open?scenario=H2}"
WARM="${WARM:-}"
HOT_SCENARIO="${HOT_SCENARIO:-hot_uriScheme}"
CAPTURE_NAME="${CAPTURE_NAME:-wire-$HOT_SCENARIO}"

# The consent SpringBoard otherwise asks for on the first `simctl openurl` of the scheme.
APPROVAL_DOMAIN="com.apple.launchservices.schemeapproval"
APPROVAL_KEY="com.apple.CoreSimulator.CoreSimulatorBridge-->${H2_URL%%:*}"

fail() { echo "ERROR: $*"; exit 1; }
driver_start=$(date +%s)

case "$HOT_SCENARIO" in
    hot_uriScheme|hot_https_foreground) ;;
    *) fail "unknown HOT_SCENARIO: $HOT_SCENARIO (expected hot_uriScheme or hot_https_foreground)" ;;
esac

# 1. Device on exactly H2_EXPECT_RUNTIME. The same name can exist on several runtimes.
selection=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
name, udid, expected = sys.argv[1], sys.argv[2], sys.argv[3]
for runtime, devices in json.load(sys.stdin)["devices"].items():
    if not runtime.endswith("." + expected):
        continue
    for d in devices:
        if d.get("isAvailable") and (d["udid"] == udid if udid else d.get("name") == name):
            print(d["udid"], runtime.rsplit(".", 1)[-1])
            sys.exit(0)
sys.exit(1)
' "$SIM_NAME" "$SIM_UDID" "$H2_EXPECT_RUNTIME") \
    || fail "no available ${SIM_UDID:+device with SIM_UDID}${SIM_UDID:-'$SIM_NAME'} on runtime $H2_EXPECT_RUNTIME"
udid=${selection% *}
echo "RUNTIME=${selection#* }"

# 2. Boot.
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null

# 3. Seed consent. It survives an uninstall, so once per device is enough.
xcrun simctl spawn "$udid" defaults write "$APPROVAL_DOMAIN" "$APPROVAL_KEY" -string "$BUNDLE_ID"
approval=$(xcrun simctl spawn "$udid" defaults read "$APPROVAL_DOMAIN" "$APPROVAL_KEY" 2>/dev/null) || approval=""
[ "$approval" = "$BUNDLE_ID" ] || fail "consent key did not read back"
echo "consent key: set"

# 4. Fresh install of the single built TestBed.
shopt -s nullglob
apps=("$DERIVED_DATA_DIR"/Build/Products/*-iphonesimulator/Branch-TestBed.app)
shopt -u nullglob
[ "${#apps[@]}" -eq 1 ] || fail "expected one Branch-TestBed.app under $DERIVED_DATA_DIR/Build/Products, found ${#apps[@]}"
xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
if [ "$HOT_SCENARIO" = "hot_uriScheme" ]; then
    xcrun simctl uninstall "$udid" "$BUNDLE_ID" 2>/dev/null || true
fi
xcrun simctl install "$udid" "${apps[0]}"

log_path() {
    local container
    container=$(xcrun simctl get_app_container "$udid" "$BUNDLE_ID" data 2>/dev/null) || return 1
    echo "$container/Documents/branchlogs.txt"
}

app_pid() {
    xcrun simctl spawn "$udid" launchctl list 2>/dev/null \
        | awk -v label="UIKitApplication:$BUNDLE_ID" 'index($3, label) == 1 { print $1 }'
}

# Prints why the TestBed went away, then fails. Never prints branchlogs.txt (wire payloads); every probe is best-effort.
diag_fail() {
    local report
    echo "DIAG: launchctl rows for UIKitApplication:$BUNDLE_ID (pid status label):"
    { xcrun simctl spawn "$udid" launchctl list 2>/dev/null \
        | awk -v label="UIKitApplication:$BUNDLE_ID" 'index($3, label) == 1 { print "DIAG: " $0; n++ } n == 3 { exit } END { if (!n) print "DIAG: none" }'; } || true
    echo "DIAG: simulator log since driver start, termination lines for $BUNDLE_ID:"
    { perl -e 'alarm 60; exec @ARGV' xcrun simctl spawn "$udid" log show --style compact \
        --start "$(date -r "$driver_start" '+%Y-%m-%d %H:%M:%S')" \
        --predicate "(process IN {\"runningboardd\", \"launchd_sim\", \"launchd\", \"SpringBoard\"}) AND (eventMessage CONTAINS \"$BUNDLE_ID\") AND (eventMessage CONTAINS[c] \"terminat\" OR eventMessage CONTAINS[c] \"exit\" OR eventMessage CONTAINS[c] \"jetsam\" OR eventMessage CONTAINS[c] \"crash\" OR eventMessage CONTAINS[c] \"killed\")" \
        2>/dev/null | grep -E '^[0-9]{4}-' | tail -n 8 | cut -c1-400 | sed 's/^/DIAG: /'; } || true
    # ReportCrash writes the .ips asynchronously, so give it up to 10s to appear.
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        report=$({ ls -t "$HOME"/Library/Logs/DiagnosticReports/Branch-TestBed*.ips 2>/dev/null | head -n 1; } || true)
        if [ -n "$report" ] && [ "$(stat -f %m "$report" 2>/dev/null || echo 0)" -ge "$driver_start" ]; then break; fi
        report=""
        sleep 1
    done
    if [ -n "$report" ]; then
        echo "DIAG: crash report: $(basename "$report")"
        { python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as f:
        f.readline()
        body = json.load(f)
except Exception as e:
    print("DIAG: crash report unreadable: " + type(e).__name__)
    sys.exit(0)
for key in ("exception", "termination"):
    print("DIAG: " + key + ": " + json.dumps(body.get(key), sort_keys=True)[:300])
' "$report" 2>/dev/null; } || true
    else
        echo "DIAG: no Branch-TestBed crash report newer than this run after 10s"
    fi
    fail "$@"
}

# Waits until the log is non-empty and its size unchanged for SETTLE_S; $1 names what failed to settle.
wait_settled() {
    local what="${1:-branchlogs.txt}" path size last=-1 same=0 elapsed=0
    while [ "$elapsed" -lt "$SETTLE_MAX_S" ]; do
        size=0
        if path=$(log_path) && [ -f "$path" ]; then size=$(stat -f %z "$path" 2>/dev/null) || size=0; fi
        if [ "$size" -gt 0 ] && [ "$size" = "$last" ]; then same=$((same + 1)); else same=0; fi
        last=$size
        if [ "$same" -ge "$SETTLE_S" ]; then echo "settled after ${elapsed}s"; return 0; fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    diag_fail "$what did not settle within ${SETTLE_MAX_S}s"
}

# Waits until the log is larger than $1 bytes, so a slow delivery is not snapshotted early.
wait_grown() {
    local path size elapsed=0
    while [ "$elapsed" -lt "$SETTLE_MAX_S" ]; do
        size=0
        if path=$(log_path) && [ -f "$path" ]; then size=$(stat -f %z "$path" 2>/dev/null) || size=0; fi
        if [ "$size" -gt "$1" ]; then return 0; fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    diag_fail "branchlogs.txt did not grow past the pre snapshot within ${SETTLE_MAX_S}s"
}

# Waits until applicationDidEnterBackground is logged after the first $1 bytes.
wait_backgrounded() {
    local path found elapsed=0
    while [ "$elapsed" -lt "$SETTLE_MAX_S" ]; do
        found=0
        if path=$(log_path) && [ -f "$path" ]; then
            found=$(tail -c +$(($1 + 1)) "$path" | grep -c '\[TestBedLifecycle\] applicationDidEnterBackground' || true)
        fi
        if [ "$found" -gt 0 ]; then return 0; fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    diag_fail "TestBed did not log applicationDidEnterBackground within ${SETTLE_MAX_S}s of launching Preferences"
}

mkdir -p "$OUTPUT_DIR"
pre="$OUTPUT_DIR/$CAPTURE_NAME.pre.txt"
post="$OUTPUT_DIR/$CAPTURE_NAME.post.txt"

# 5. Remove a log left by a previous run, then launch and settle.
if stale=$(log_path); then rm -f "$stale"; fi
xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
wait_settled
pid=$(app_pid)
[[ $pid =~ ^[0-9]+$ ]] || diag_fail "TestBed is not running after launch"

# 6. Snapshot. A launch that never opened is not a hot app.
cp "$(log_path)" "$pre"
grep -qE '\[BranchLog\] Got https?://[^ ]+/v3/events/open Request:' "$pre" || fail "launch did not settle"

# 6b. Warm: background the same process, then retake pre so it holds the resign and background markers.
if [ "$WARM" = "1" ]; then
    xcrun simctl launch "$udid" com.apple.Preferences >/dev/null
    wait_backgrounded "$(stat -f %z "$pre")"
    wait_settled "backgrounding"
    bg_pid=$(app_pid)
    [[ $bg_pid =~ ^[0-9]+$ ]] || diag_fail "TestBed not running after background"
    [ "$bg_pid" = "$pid" ] || diag_fail "relaunched during background"
    echo "backgrounded, pid unchanged"
    cp "$(log_path)" "$pre"
fi

# 7. Deliver, retrying while LaunchServices is still settling after boot.
attempt=0
start=$SECONDS
while :; do
    attempt=$((attempt + 1))
    rc=0
    output=$(xcrun simctl openurl "$udid" "$H2_URL" 2>&1) || rc=$?
    echo "openurl attempt $attempt exit=$rc"
    [ "$rc" -eq 0 ] && break
    if [[ $output != *Code=115* ]]; then
        reason=""
        [[ $output =~ Domain=[A-Za-z]+\ Code=-?[0-9]+ ]] && reason=${BASH_REMATCH[0]}
        fail "openurl failed: $reason"
    fi
    [ $((SECONDS - start + 10)) -le "$OPENURL_MAX_S" ] || fail "openurl still returned Code=115 after ${OPENURL_MAX_S}s"
    sleep 10
done

# 8. Wait for the delivery to land, settle, snapshot, and prove it reached the same process.
wait_grown "$(stat -f %z "$pre")"
wait_settled
cp "$(log_path)" "$post"
post_pid=$(app_pid)
[[ $post_pid =~ ^[0-9]+$ ]] || diag_fail "TestBed is not running after delivery"
[ "$post_pid" = "$pid" ] || diag_fail "relaunched"
echo "pid unchanged"

# 9. hot_https_foreground only: gate on the TestBed's lifecycle markers.
if [ "$HOT_SCENARIO" = "hot_https_foreground" ]; then
    python3 "$(dirname "$0")/check_foreground_markers.py" "$post" --pre "$pre" --scenario "$HOT_SCENARIO"
fi
