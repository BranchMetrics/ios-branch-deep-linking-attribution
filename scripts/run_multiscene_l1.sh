#!/usr/bin/env bash
#
# Runs the multi-scene L1 captures on an iPad simulator and checks each one.
#
# For every scenario this script:
#   1. Runs its UI test class through scripts/run_l1_instrumented.sh with
#      REQUIRE_MULTI_SCENE=1, which writes <OUTPUT_DIR>/wire-<scenario>.txt.
#   2. Checks the capture against its wire contract (validate_l1_logs.py).
#   3. Checks which scene's callback received each result (check_scene_routing.py).
# It prints a pass/fail line per scenario at the end, and exits 1 if any failed.
#
# Build iOSReleaseTest for testing into DERIVED_DATA_DIR first (scripts/README.md).
#
# Env / inputs:
#   SIM_NAME           - iPad simulator name (default: first iPad on the newest iOS runtime)
#   SIM_UDID           - iPad simulator UDID; overrides SIM_NAME. With neither set, the
#                        UDID of the chosen iPad is passed on, since one name can exist on
#                        several runtimes
#   DERIVED_DATA_DIR   - build-for-testing output (default ./DerivedData)
#   OUTPUT_DIR         - where the captures are written (default .)
#   SCENARIOS          - space-separated subset to run (default: all four)
#   REQUIRE_LINK_DATA  - 1 passes --require-link-data to the link scenarios' routing
#                        check, so a fixture link that does not resolve fails (default 0)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-./DerivedData}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"
SCENARIOS="${SCENARIOS:-multiscene_open multiscene_link_scene2 multiscene_link_scene1 multiscene_foreground}"
REQUIRE_LINK_DATA="${REQUIRE_LINK_DATA:-0}"

# Returns the UI test class for a scenario.
test_class_for() {
    case "$1" in
        multiscene_open) echo MultiSceneOpenWireTest ;;
        multiscene_link_scene2) echo MultiSceneLinkToScene2WireTest ;;
        multiscene_link_scene1) echo MultiSceneLinkToScene1WireTest ;;
        multiscene_foreground) echo MultiSceneForegroundWireTest ;;
        *) return 1 ;;
    esac
}

for scenario in $SCENARIOS; do
    if ! test_class_for "$scenario" > /dev/null; then
        echo "ERROR: unknown scenario '$scenario'. Known: multiscene_open multiscene_link_scene2 multiscene_link_scene1 multiscene_foreground"
        exit 2
    fi
done

SIM_UDID="${SIM_UDID:-}"
if [ -z "$SIM_UDID" ] && [ -z "${SIM_NAME:-}" ]; then
    picked=$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
def version(runtime):
    return [int(n) for n in re.findall(r"\d+", runtime.rsplit("iOS-", 1)[-1])]
for runtime in sorted((r for r in devices if ".iOS-" in r), key=version, reverse=True):
    ipads = sorted((d["name"], d["udid"]) for d in devices[runtime] if d.get("isAvailable") and d["name"].startswith("iPad"))
    if ipads:
        print(ipads[0][1] + "\t" + ipads[0][0] + " (" + runtime.rsplit(".", 1)[-1] + ")")
        break
')
    SIM_UDID="${picked%%$'\t'*}"
    SIM_NAME="${picked#*$'\t'}"
    if [ -z "$picked" ]; then
        echo "ERROR: no iPad simulator available; set SIM_NAME or install an iPad runtime."
        exit 1
    fi
fi

if [ ! -d "$DERIVED_DATA_DIR" ]; then
    echo "ERROR: $DERIVED_DATA_DIR does not exist; build iOSReleaseTest for testing first (scripts/README.md)."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "==> Multi-scene L1 captures"
echo "    Simulator         : ${SIM_NAME:-}${SIM_UDID:+ [$SIM_UDID]}"
echo "    Derived data dir  : $DERIVED_DATA_DIR"
echo "    Output dir        : $OUTPUT_DIR"
echo "    Scenarios         : $SCENARIOS"
echo "    Require link data : $REQUIRE_LINK_DATA"

SUMMARY=()
FAILED=0

for scenario in $SCENARIOS; do
    capture="$OUTPUT_DIR/wire-$scenario.txt"
    echo
    echo "==> [$scenario] capturing"

    status="pass"
    if ! SIM_NAME="${SIM_NAME:-iPad}" \
         SIM_UDID="$SIM_UDID" \
         DERIVED_DATA_DIR="$DERIVED_DATA_DIR" \
         REQUIRE_MULTI_SCENE=1 \
         UNINSTALL_FIRST=1 \
         ONLY_TESTING="iOSReleaseTestUITests/$(test_class_for "$scenario")" \
         OUTPUT_LOG="$capture" \
         "$SCRIPT_DIR/run_l1_instrumented.sh"; then
        status="fail (UI test)"
    fi

    echo "==> [$scenario] wire contract"
    if ! python3 "$SCRIPT_DIR/validate_l1_logs.py" "$capture" --scenario "$scenario"; then
        status="fail"
    fi

    routing_args=(--scenario "$scenario")
    case "$scenario" in
        multiscene_link_*) [ "$REQUIRE_LINK_DATA" = "1" ] && routing_args+=(--require-link-data) ;;
    esac
    echo "==> [$scenario] scene routing"
    if ! python3 "$SCRIPT_DIR/check_scene_routing.py" "$capture" "${routing_args[@]}"; then
        status="fail"
    fi

    [ "$status" = "pass" ] || FAILED=1
    SUMMARY+=("$scenario: $status ($capture)")
done

echo
echo "==> Summary"
for line in "${SUMMARY[@]}"; do
    echo "    $line"
done

exit "$FAILED"
