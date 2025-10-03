#!/bin/bash
#  version  -  Version number management.
#  Edward Smith,  December 2016.
set -euo pipefail
function usage() {
cat <<USAGE
version  -  Print or increment a version number.

Usage:  version.sh  [ -hiMmp ]

With no options given, \`version.sh\` simply prints the current version number.

Version numbers are:  Major.Minor.Patch

Options:

  -h  Print this usage info.
  -i  Increment the version number.  By default this increments the patch number.
  -u  Update all source files for the update.  The '-i' version implies this option.

    Updates version numbers in files:

        Branch version:     ../BranchSDK/BNCConfig.m
        Podspec version:    ../BranchSDK.podspec

  -M  Print or increment the \`major\` version number.
  -m  Print or increment the \`minor\` version number.
  -p  Print or increment the \`patch\` version number.

USAGE
}

version=3.13.3
prev_version="$version"

if (( $# == 0 )); then
    echo $version
    exit 0
fi

scriptfile="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scriptfile="${scriptfile}"/$(basename "$0")
cd $(dirname "$scriptfile")


IFS=$'.' read  M m p < <(echo "$version")

major=
minor=
patch=
increment=
update=

while getopts ":hiMmpvu" option; do
    case "$option" in
    h)  usage; exit 0 ;;
    i)  increment=true; update=true ;;
    M)  major=true ;;
    m)  minor=true ;;
    p)  patch=true ;;
    u)  update=true ;;
    v)  ;;
    ?)  echo ">>> Error: Unknown option '-$OPTARG'." 1>&2; exit 1 ;;
    esac
done


if [[ $increment ]]; then

    if [[ $major ]]; then
        let M=M+1
        m=0
        p=0
    elif [[ $minor ]]; then
        let m=m+1
        p=0
    else
        let p=p+1
    fi

    version="$M.$m.$p"
    echo "$version"

else

    #  Print the version or parts

    if   [[ $major ]]; then
        echo $M
    elif [[ $minor ]]; then
        echo $m
    elif [[ $patch ]]; then
        echo $p
    else
        echo "$version"
    fi

fi


if [[ $update ]]; then

    # Update the SDK version:
    sed -i '' -e "/BNC_SDK_VERSION/ {s/\".*\"/\"$version\"/; }" ../Sources/BranchSDK/BNCConfig.m

    # Update the Podspec version:
    sed -i '' -e "/^[[:space:]]*s\.version/ {s/\".*\"/\"$version\"/; }" ../BranchSDK.podspec
  
    # Update framework version
    sed -i '' -e 's/MARKETING_VERSION = '"$prev_version"'/MARKETING_VERSION = '"$version"'/g' ../BranchSDK.xcodeproj/project.pbxproj
fi


if [[ $increment ]]; then
    # Update our version (Do this last. Updating a running bash script has undefined results.)
    sed -i '' -e "s/^version=.*$/version=$version/" "$scriptfile"; exit 0
fi
