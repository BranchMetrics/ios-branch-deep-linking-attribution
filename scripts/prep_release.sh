#!/bin/bash
set -euo pipefail

# prep_release.sh - prepares release candidate for testing
#
# This script is written to be excessively modular so it can be debugged or restarted easily.
#
# Edward Smith, December 2016

scriptfile="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scriptfile="${scriptfile}"/$(basename "$0")
cd $(dirname "$scriptfile")/..

scriptFailed=1
function finish {
    if [ $scriptFailed -ne 0 ]; then
        echo ">>> Error: `basename "$scriptfile"` failed!" 1>&2
        exit 1
    fi
}
trap finish EXIT


version=$(./scripts/version.sh)

echo ""
echo "Before continuing:"
echo "- Make sure that the release version number is already updated."
echo "- Make sure that the ChangeLog.md has been updated, spell checked, and is coherent."
echo "- Unit tests pass in Xcode"
echo ""
if ! ./scripts/askYN.sh "Build Branch release candidate version ${version}?"; then
    echo ">>> Nothing built." 1>&2
    exit 1
fi

# Prompt for editor input for ChangeLog.
"${VISUAL:-nano}" ChangeLog.md

# Check that deployment software is installed
./scripts/check_build_environment.sh

# Pre-release CocoaPod lint
echo ">>> Linting release candidate..." 1>&2
pod lib lint Branch.podspec --verbose --allow-warnings

# Build the frameworks
echo ">>> Building the frameworks..." 1>&2
./scripts/build_framework.sh
./scripts/build_static_framework.sh

echo ""
echo "SDK release candidate is ready for testing"

# Completed OK:
scriptFailed=0
