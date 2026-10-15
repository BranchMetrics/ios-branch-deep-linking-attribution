#!/bin/bash
#  test_version  -  Tests for version.sh and validate_version.sh.
#
#  Runs both scripts against copies of the files they manage, in a temporary directory.
#  The repo itself is never modified.
#
#  Usage:  ./scripts/test_version.sh
set -uo pipefail

repo="$( cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

passed=0
failed=0

#  setup  <version>
#  Copies the managed files into $work and sets them all to <version>.
function setup() {
    rm -rf "$work"/*
    mkdir -p "$work/scripts" "$work/Sources/BranchSDK" "$work/BranchSDK.xcodeproj"
    cp "$repo/scripts/version.sh" "$repo/scripts/validate_version.sh" "$work/scripts/"
    cp "$repo/Sources/BranchSDK/BNCConfig.m" "$work/Sources/BranchSDK/"
    cp "$repo/BranchSDK.podspec" "$work/"
    cp "$repo/BranchSDK.xcodeproj/project.pbxproj" "$work/BranchSDK.xcodeproj/"
    "$work/scripts/version.sh" -s "$1" > /dev/null
}

function fingerprint() {
    (cd "$work" && cat scripts/version.sh Sources/BranchSDK/BNCConfig.m BranchSDK.podspec \
        BranchSDK.xcodeproj/project.pbxproj | shasum)
}

#  test_files  <name>  <version>  <marketing_version>
function test_files() {
    local config podspec marketing others
    config=$(sed -n 's/.*BNC_SDK_VERSION.*@"\(.*\)".*/\1/p' "$work/Sources/BranchSDK/BNCConfig.m")
    podspec=$(sed -n 's/^[[:space:]]*s\.version[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$work/BranchSDK.podspec")
    marketing=$(perl -0ne '
        while (/buildSettings = \{(.*?)\n\t\t\t\};/sg) {
            my $settings = $1;
            next unless $settings =~ /PRODUCT_BUNDLE_IDENTIFIER = io\.branch\.BranchSDK;/;
            print "$1\n" if $settings =~ /MARKETING_VERSION = ([^;]*);/;
        }' "$work/BranchSDK.xcodeproj/project.pbxproj" | sort -u | tr '\n' ' ')
    others=$(grep -c 'MARKETING_VERSION = 1.0;' "$work/BranchSDK.xcodeproj/project.pbxproj")
    if [[ "$config" == "$2" && "$podspec" == "$2" && "$marketing" == "$3 " && "$others" == 4 &&
          "$("$work/scripts/version.sh")" == "$2" ]]; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        echo "FAIL: $1: config='$config' podspec='$podspec' marketing='$marketing' test targets at 1.0=$others"
    fi
}

#  test_output  <name>  <expected output>  <command...>
function test_output() {
    local name="$1" expected="$2" actual
    shift 2
    actual=$("$@" 2> /dev/null)
    if [[ "$actual" == "$expected" ]]; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        echo "FAIL: $name: expected '$expected', got '$actual'"
    fi
}

#  test_rejects  <name>  <command...>
#  Expects the command to exit non-zero and leave every file unchanged.
function test_rejects() {
    local name="$1" before
    shift
    before=$(fingerprint)
    if "$@" > /dev/null 2>&1; then
        failed=$((failed + 1))
        echo "FAIL: $name: expected a non-zero exit"
    elif [[ "$(fingerprint)" != "$before" ]]; then
        failed=$((failed + 1))
        echo "FAIL: $name: files were modified"
    else
        passed=$((passed + 1))
    fi
}

version="$work/scripts/version.sh"
validate="$work/scripts/validate_version.sh"

# Printing
setup 4.0.0-beta.2
test_output "print"            "4.0.0-beta.2" "$version"
test_output "print core"       "4.0.0"        "$version" -x
test_output "print major"      "4"            "$version" -M
test_output "print minor"      "0"            "$version" -m
test_output "print patch"      "0"            "$version" -p
test_output "check"            "Source files match version 4.0.0-beta.2." "$version" -c

# Setting
setup 4.0.0-beta.2
test_output "set"              "4.0.0-beta.3" "$version" -s 4.0.0-beta.3
test_files  "set"              "4.0.0-beta.3" "4.0.0"
setup 4.0.0-beta.2
"$version" -s 4.1.0-rc.1 > /dev/null
test_files  "set rc"           "4.1.0-rc.1"   "4.1.0"
setup 4.0.0-beta.2
"$version" -s 4.0.0 > /dev/null
test_files  "set release"      "4.0.0"        "4.0.0"

# Incrementing
setup 4.0.0-beta.2
test_output "increment prerelease"   "4.0.0-beta.3" "$version" -i
test_files  "increment prerelease"   "4.0.0-beta.3" "4.0.0"
setup 4.0.0-beta.2
test_output "increment -p prerelease" "4.0.0" "$version" -i -p
test_files  "increment -p prerelease" "4.0.0" "4.0.0"
setup 4.0.0-beta.2
test_output "increment -m prerelease" "4.1.0" "$version" -i -m
test_files  "increment -m prerelease" "4.1.0" "4.1.0"
setup 4.0.0-beta.2
test_output "increment -M prerelease" "5.0.0" "$version" -i -M
test_files  "increment -M prerelease" "5.0.0" "5.0.0"
setup 4.0.0
test_output "increment release"      "4.0.1" "$version" -i
test_files  "increment release"      "4.0.1" "4.0.1"
setup 4.0.9-beta.9
test_output "increment past 9"       "4.0.9-beta.10" "$version" -i

# Invalid input
setup 4.0.0-beta.2
for bad in 4.0 4 v4.0.0 4.0.0-beta 4.0.0-beta.03 4.0.0-gamma.1 4.0.0-BETA.1 04.0.0 4.0.0.1 \
        "4.0.0-beta.2 " " 4.0.0" "4.0.0-beta.2-1" "4.0.0+build.1" ""; do
    test_rejects "set '$bad'" "$version" -s "$bad"
done
test_rejects "missing -s argument"   "$version" -s
test_rejects "-s with -i"            "$version" -s 4.0.0-beta.3 -i
test_rejects "-c with -u"            "$version" -c -u
test_rejects "unknown option"        "$version" -q
test_rejects "extra argument"        "$version" -x extra

# Check detects drift
setup 4.0.0-beta.2
sed -i '' -e 's/"4.0.0-beta.2"/"4.0.0-beta.1"/' "$work/BranchSDK.podspec"
test_rejects "check podspec drift"   "$version" -c
setup 4.0.0-beta.2
sed -i '' -e '/BNC_SDK_VERSION/ s/4.0.0-beta.2/4.0.0-beta.1/' "$work/Sources/BranchSDK/BNCConfig.m"
test_rejects "check config drift"    "$version" -c
setup 4.0.0-beta.2
perl -0pi -e 's/MARKETING_VERSION = 4\.0\.0;/MARKETING_VERSION = 3.12.1;/' "$work/BranchSDK.xcodeproj/project.pbxproj"
test_rejects "check marketing drift" "$version" -c

# validate_version.sh
setup 4.0.0-beta.2
test_output  "validate prerelease" "$(printf 'version=4.0.0-beta.2\nprerelease=true')" "$validate" 4.0.0-beta.2
test_rejects "validate other version"    "$validate" 4.0.0-beta.3
test_rejects "validate malformed"        "$validate" v4.0.0-beta.2
test_rejects "validate no argument"      "$validate"
setup 4.0.0
test_output  "validate release"    "$(printf 'version=4.0.0\nprerelease=false')" "$validate" 4.0.0
setup 4.0.0-beta.2
sed -i '' -e 's/"4.0.0-beta.2"/"4.0.0-beta.1"/' "$work/BranchSDK.podspec"
test_rejects "validate drift"            "$validate" 4.0.0-beta.2

echo "$passed passed, $failed failed"
(( failed == 0 ))
