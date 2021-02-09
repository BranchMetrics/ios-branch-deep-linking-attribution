#!/bin/bash
set -euo pipefail

# release_sdk.sh  -  The release deployment master script.
#
# This script is written to be excessively modular so it can be debugged or restarted easily.
#
# Edward Smith, December 2016

scriptfile="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scriptfile="${scriptfile}"/$(basename "$0")
cd $(dirname "$scriptfile")/..

scriptpath="${BASH_SOURCE[0]}"
scriptpath=$(cd "$(dirname "${scriptpath}")" && pwd)

scriptFailed=1
function finish {
    if [ $scriptFailed -ne 0 ]; then
        echo ">>> Error: `basename "$scriptfile"` failed!" 1>&2
        exit 1
    fi
}
trap finish EXIT


version=$(./scripts/version.sh)

# Sanity check that build products are available
if [ ! -f "${scriptpath}/../carthage-files/Branch.zip" ]; then 
    echo "Branch.zip not found"
    exit 1
fi

if [ ! -f "${scriptpath}/../carthage-files/Branch_static.zip" ]; then
    echo "Branch-static.zip not found"
    exit 1
fi

if ! ./scripts/askYN.sh "Commit and deploy Branch ${version}?"; then
    echo ">>> Nothing deployed." 1>&2
    exit 1
fi

echo '>>> Commit and tag...' 1>&2
./scripts/git_commit_and_tag.sh

echo '>>> Pushing Branch CocoaPod...' 1>&2
pod trunk push Branch.podspec

# Prompts for SDK Release announcements
./scripts/announce_sdk_release.sh

echo ""
echo "The Branch SDK has been released.  Rejoice and pay tribute to Steve Jobs!"
# Completed OK:
scriptFailed=0
