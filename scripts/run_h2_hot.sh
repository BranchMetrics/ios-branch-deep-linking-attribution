#!/usr/bin/env bash
#
# hot_uriScheme / hot_https_foreground driver for the iOS Branch SDK TestBed.
#
# Launches the TestBed, snapshots branchlogs.txt once the launch settles, opens
# a scheme URL into the foregrounded app with `simctl openurl`, and snapshots
# again. Validate with:
#
#   validate_l1_logs.py "$OUTPUT_DIR/wire-$HOT_SCENARIO.post.txt" \
#       --scenario "$HOT_SCENARIO" --pre "$OUTPUT_DIR/wire-$HOT_SCENARIO.pre.txt"
#
# Required env:
#   H2_EXPECT_RUNTIME  - runtime the device must be on, for example iOS-18-5
# Optional env:
#   HOT_SCENARIO       - hot_uriScheme or hot_https_foreground (default hot_uriScheme)
#   DERIVED_DATA_DIR   - build-for-testing output (default ./DerivedData)
#   SIM_NAME           - simulator device name (default "iPhone 16 Plus")
#   SIM_UDID           - select this device instead of matching SIM_NAME
#   BUNDLE_ID          - TestBed bundle id (default io.branch.sdk.Branch-TestBed)
#   OUTPUT_DIR         - where the snapshots go (default .)
#   SETTLE_S           - seconds the log must stay unchanged (default 10)
#   SETTLE_MAX_S       - give up settling after this many seconds (default 120)
#   OPENURL_MAX_S      - retry budget for LaunchServices error 115 (default 120)
#   H2_URL             - URL to deliver (default branchtest://open?scenario=H2)

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
HOT_SCENARIO="${HOT_SCENARIO:-hot_uriScheme}"

# The consent SpringBoard otherwise asks for on the first `simctl openurl` of the scheme.
APPROVAL_DOMAIN="com.apple.launchservices.schemeapproval"
APPROVAL_KEY="com.apple.CoreSimulator.CoreSimulatorBridge-->${H2_URL%%:*}"

fail() { echo "ERROR: $*"; exit 1; }

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

# 4. Install the single built TestBed. hot_uriScheme reinstalls fresh every
#    run; hot_https_foreground installs in place, keeping app data.
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

# Waits until the log is non-empty and its size unchanged for SETTLE_S.
wait_settled() {
    local path size last=-1 same=0 elapsed=0
    while [ "$elapsed" -lt "$SETTLE_MAX_S" ]; do
        size=0
        if path=$(log_path) && [ -f "$path" ]; then size=$(stat -f %z "$path"); fi
        if [ "$size" -gt 0 ] && [ "$size" = "$last" ]; then same=$((same + 1)); else same=0; fi
        last=$size
        if [ "$same" -ge "$SETTLE_S" ]; then echo "settled after ${elapsed}s"; return 0; fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    fail "branchlogs.txt did not settle within ${SETTLE_MAX_S}s"
}

# Waits until the log is larger than $1 bytes, so a slow delivery is not snapshotted early.
wait_grown() {
    local path size elapsed=0
    while [ "$elapsed" -lt "$SETTLE_MAX_S" ]; do
        size=0
        if path=$(log_path) && [ -f "$path" ]; then size=$(stat -f %z "$path"); fi
        if [ "$size" -gt "$1" ]; then return 0; fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    fail "branchlogs.txt did not grow past the pre snapshot within ${SETTLE_MAX_S}s"
}

mkdir -p "$OUTPUT_DIR"
pre="$OUTPUT_DIR/wire-$HOT_SCENARIO.pre.txt"
post="$OUTPUT_DIR/wire-$HOT_SCENARIO.post.txt"

# 5. Launch and settle.
xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
wait_settled
pid=$(app_pid)
[[ $pid =~ ^[0-9]+$ ]] || fail "TestBed is not running after launch"

# 6. Snapshot. A launch that never opened is not a hot app.
cp "$(log_path)" "$pre"
grep -qE '\[BranchLog\] Got https?://[^ ]+/v3/events/open Request:' "$pre" || fail "launch did not settle"

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
[[ $post_pid =~ ^[0-9]+$ ]] || fail "TestBed is not running after delivery"
[ "$post_pid" = "$pid" ] || fail "relaunched"
echo "pid unchanged"

# 9. hot_https_foreground only: gate on the TestBed's lifecycle markers.
if [ "$HOT_SCENARIO" = "hot_https_foreground" ]; then
    python3 "$(dirname "$0")/check_foreground_markers.py" "$post" --pre "$pre" --scenario "$HOT_SCENARIO"
fi
