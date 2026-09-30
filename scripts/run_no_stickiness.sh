#!/usr/bin/env bash
#
# no_stickiness driver for the iOS Branch SDK TestBed.
#
# Delivers the fixture link through the TestBed's in-process deep link hook
# (a relaunch with -testDeepLinkURL, since the hook reads it only at launch),
# backgrounds the app for real, returns with no URL, and snapshots
# branchlogs.txt right before the return. Validate with:
#
#   check_no_stickiness.py "$OUTPUT_DIR/wire-no_stickiness.post.txt" \
#       --pre "$OUTPUT_DIR/wire-no_stickiness.pre.txt"
#
# This driver runs the checker itself and exits with its code (0 pass, 1
# fail, 2 unparseable report line).
#
# Required env:
#   NS_EXPECT_RUNTIME  - runtime the device must be on, for example iOS-18-4
# Optional env:
#   DERIVED_DATA_DIR   - build-for-testing output (default ./DerivedData)
#   SIM_NAME           - simulator device name (default "iPhone 16 Plus")
#   SIM_UDID           - select this device instead of matching SIM_NAME
#   BUNDLE_ID          - TestBed bundle id (default io.branch.sdk.Branch-TestBed)
#   OUTPUT_DIR         - where the snapshots go (default .)
#   SETTLE_S           - seconds the log must stay unchanged (default 10)
#   SETTLE_MAX_S       - give up settling after this many seconds (default 120)
#   LINK_MAX_S         - budget for the link to resolve and chain an open (default 60)
#   BG_MAX_S           - budget for the background marker (default 30)
#   BG_REPORT_MAX_S    - budget for the background-side report after the marker (default 15)
#   RETURN_MAX_S       - budget for the return marker and its report (default 30)
#   NS_URL             - fixture link to deliver (default the bnctestbed.app.link fixture)

set -euo pipefail

: "${NS_EXPECT_RUNTIME:?NS_EXPECT_RUNTIME is required, for example iOS-18-4}"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-./DerivedData}"
SIM_NAME="${SIM_NAME:-iPhone 16 Plus}"
SIM_UDID="${SIM_UDID:-}"
BUNDLE_ID="${BUNDLE_ID:-io.branch.sdk.Branch-TestBed}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"
SETTLE_S="${SETTLE_S:-10}"
SETTLE_MAX_S="${SETTLE_MAX_S:-120}"
LINK_MAX_S="${LINK_MAX_S:-60}"
BG_MAX_S="${BG_MAX_S:-30}"
BG_REPORT_MAX_S="${BG_REPORT_MAX_S:-15}"
RETURN_MAX_S="${RETURN_MAX_S:-30}"
NS_URL="${NS_URL:-https://bnctestbed.app.link/7HTLJ2jXi3b}"

fail() {
    echo "ERROR: $*"
    local src
    if [ -n "${udid:-}" ] && src=$(log_path 2>/dev/null) && [ -f "$src" ]; then
        mkdir -p "$OUTPUT_DIR" && cp "$src" "$OUTPUT_DIR/wire-no_stickiness.fail.txt" || true
    fi
    exit 1
}

# 1. Device on exactly NS_EXPECT_RUNTIME. The same name can exist on several runtimes.
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
' "$SIM_NAME" "$SIM_UDID" "$NS_EXPECT_RUNTIME") \
    || fail "no available ${SIM_UDID:+device with SIM_UDID}${SIM_UDID:-'$SIM_NAME'} on runtime $NS_EXPECT_RUNTIME"
udid=${selection% *}
echo "RUNTIME=${selection#* }"

# 2. Boot.
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null

# No scheme-approval consent seeding: NS_URL is never opened through LaunchServices.

# 3. Fresh install of the single built TestBed.
shopt -s nullglob
apps=("$DERIVED_DATA_DIR"/Build/Products/*-iphonesimulator/Branch-TestBed.app)
shopt -u nullglob
[ "${#apps[@]}" -eq 1 ] || fail "expected one Branch-TestBed.app under $DERIVED_DATA_DIR/Build/Products, found ${#apps[@]}"
xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl uninstall "$udid" "$BUNDLE_ID" 2>/dev/null || true
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

# Waits for the delivered link's chain: /v3/deeplink, a chained /v3/events/open, then a report carrying this run's +clicked_branch_link.
wait_link_resolved() {
    local path elapsed=0 deeplink_line open_line
    while [ "$elapsed" -lt "$LINK_MAX_S" ]; do
        if path=$(log_path) && [ -f "$path" ]; then
            deeplink_line=$(grep -nE '\[BranchLog\] Got https?://[^ ]*/v3/deeplink Request:' "$path" | tail -1 | cut -d: -f1) || deeplink_line=""
            if [ -n "$deeplink_line" ]; then
                open_line=$(tail -n +"$((deeplink_line + 1))" "$path" | grep -nE '\[BranchLog\] Got Response for request \([^)]*/v3/events/open[^)]*\)' | tail -1 | cut -d: -f1) || open_line=""
                if [ -n "$open_line" ]; then
                    open_line=$((deeplink_line + open_line))
                    if tail -n +"$((open_line + 1))" "$path" | grep -q '\[TestBedLifecycle\] latestReferringParams.*"+clicked_branch_link":true'; then
                        return 0
                    fi
                fi
            fi
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    fail "no resolved link with a chained /v3/events/open within ${LINK_MAX_S}s"
}

# Waits for the TestBed's background marker, then for the background-side report the two main-queue hops in applicationDidEnterBackground: write after it.
wait_background_report() {
    local path elapsed=0
    while [ "$elapsed" -lt "$BG_MAX_S" ]; do
        if path=$(log_path) && [ -f "$path" ] && grep -q '\[TestBedLifecycle\] applicationDidEnterBackground' "$path"; then
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    [ "$elapsed" -lt "$BG_MAX_S" ] || fail "no applicationDidEnterBackground marker within ${BG_MAX_S}s"

    local marker_line report
    marker_line=$(grep -n '\[TestBedLifecycle\] applicationDidEnterBackground' "$path" | tail -1 | cut -d: -f1)
    elapsed=0
    while [ "$elapsed" -lt "$BG_REPORT_MAX_S" ]; do
        if path=$(log_path) && [ -f "$path" ]; then
            report=$(tail -n +"$((marker_line + 1))" "$path" | grep '\[TestBedLifecycle\] latestReferringParams' | tail -1) || report=""
            if [ -n "$report" ]; then
                if grep -q '"+clicked_branch_link":true' <<<"$report"; then
                    echo "clear did not run at background"
                else
                    echo "clear observed at background"
                fi
                return 0
            fi
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    fail "no latestReferringParams report after the background marker within ${BG_REPORT_MAX_S}s"
}

# Waits for the return's own activation marker and a report after it, past pre_size bytes.
wait_return_settled() {
    local pre_size=$1
    local path elapsed=0 size delta
    while [ "$elapsed" -lt "$RETURN_MAX_S" ]; do
        if path=$(log_path) && [ -f "$path" ]; then
            size=$(stat -f %z "$path")
            if [ "$size" -gt "$pre_size" ]; then
                delta=$(tail -c +"$((pre_size + 1))" "$path")
                if grep -q '\[TestBedLifecycle\] applicationDidBecomeActive' <<<"$delta" \
                    && grep -q '\[TestBedLifecycle\] latestReferringParams' <<<"$delta"; then
                    return 0
                fi
            fi
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    fail "no applicationDidBecomeActive + report after the return within ${RETURN_MAX_S}s"
}

mkdir -p "$OUTPUT_DIR"
pre="$OUTPUT_DIR/wire-no_stickiness.pre.txt"
post="$OUTPUT_DIR/wire-no_stickiness.post.txt"

# 4. Launch and wait for tokens to persist (the launch's own open response).
xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
wait_settled
launch_path=$(log_path)
grep -qE '\[BranchLog\] Got Response for request \([^)]*/v3/events/open[^)]*\)' "$launch_path" \
    || fail "launch did not settle: no /v3/events/open response"
pid=$(app_pid)
[[ $pid =~ ^[0-9]+$ ]] || fail "TestBed is not running after launch"

# 5. Deliver the fixture link via the in-process hook: a new process, same SDK entry point as a
# real Universal Link. Wait for it to resolve with a chained open.
xcrun simctl terminate "$udid" "$BUNDLE_ID" || true
xcrun simctl launch "$udid" "$BUNDLE_ID" -testDeepLinkURL "$NS_URL" >/dev/null \
    || fail "launch with -testDeepLinkURL failed for $NS_URL"
wait_link_resolved
pid=$(app_pid)
[[ $pid =~ ^[0-9]+$ ]] || fail "TestBed is not running after the link"
echo "link resolved, pid=$pid"

# 6. Background for real, wait for the marker and the background-side report, snapshot before the return.
xcrun simctl launch "$udid" com.apple.Preferences >/dev/null
wait_background_report
bg_epoch=$SECONDS
cp "$(log_path)" "$pre"
pre_size=$(stat -f %z "$pre")

# 7. Return with no URL, wait for the return's own marker and a report after it.
xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
wait_return_settled "$pre_size"
return_epoch=$SECONDS
echo "background-to-return gap: $((return_epoch - bg_epoch))s"
wait_settled

# 8. Snapshot, prove the same process, prove no /v3/deeplink since the return.
post_path=$(log_path)
cp "$post_path" "$post"
post_pid=$(app_pid)
[[ $post_pid =~ ^[0-9]+$ ]] || fail "TestBed is not running after the return"
[ "$post_pid" = "$pid" ] || fail "relaunched: pid was $pid, now $post_pid"
echo "pid unchanged"

deeplink_count=$(tail -c +"$((pre_size + 1))" "$post" | grep -cE '\[BranchLog\] Got https?://[^ ]*/v3/deeplink Request:') || deeplink_count=0
[ "$deeplink_count" -eq 0 ] || fail "$deeplink_count /v3/deeplink request(s) since the return"
echo "0 /v3/deeplink since the return"

# 9. Verdict.
rc=0
python3 "$(dirname "$0")/check_no_stickiness.py" "$post" --pre "$pre" || rc=$?
exit "$rc"
