#!/bin/bash
#  validate_version  -  Check that the repo is at a given release version.
set -euo pipefail
function usage() {
cat <<USAGE
validate_version  -  Check that the repo is at a given release version.

Usage:  validate_version.sh  <version>

Exits 0 when <version> equals the version in \`version.sh\` and every source file
\`version.sh\` manages matches it. Exits 1 otherwise.

On success, prints:

    version=<version>
    prerelease=true|false

USAGE
}

if (( $# != 1 )) || [[ "$1" == "-h" ]]; then
    usage
    exit 1
fi

expected="$1"
scriptdir="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

current=$("$scriptdir/version.sh")
if [[ "$expected" != "$current" ]]; then
    echo ">>> Error: Requested version '$expected' does not match the repo version '$current'." 1>&2
    echo ">>> Run \`./scripts/version.sh -s $expected\` and merge that change before releasing." 1>&2
    exit 1
fi

"$scriptdir/version.sh" -c 1>&2

prerelease=false
if [[ "$expected" == *-* ]]; then
    prerelease=true
fi

echo "version=$expected"
echo "prerelease=$prerelease"
