#!/bin/bash
#  version  -  Version number management.
#  Edward Smith,  December 2016.
set -euo pipefail
function usage() {
cat <<USAGE
version  -  Print, set, increment or check a version number.

Usage:  version.sh  [ -h ] [ -c ] [ -x ] [ -s <version> ] [ -iuMmp ]

With no options given, \`version.sh\` simply prints the current version number.

Version numbers are:  Major.Minor.Patch[-Prerelease.Number]

    Prerelease is one of: alpha, beta, rc.
    Examples:  4.0.0   4.0.0-beta.2   4.1.0-rc.1

Options:

  -h  Print this usage info.
  -s  Set the version number to <version> and update all source files.
        version.sh -s 4.0.0-beta.3
  -i  Increment the version number.
        On a prerelease version this increments the prerelease number:
            4.0.0-beta.2  ->  4.0.0-beta.3
        On a release version this increments the patch number:
            4.0.0  ->  4.0.1
  -u  Update all source files for the update.  The '-i' and '-s' options imply this option.

    Updates version numbers in files:

        Branch version:     ../Sources/BranchSDK/BNCConfig.m       (full version)
        Podspec version:    ../BranchSDK.podspec                   (full version)
        Framework version:  ../BranchSDK.xcodeproj/project.pbxproj (Major.Minor.Patch only,
                            BranchSDK framework targets only)

  -c  Check that the source files above match the current version. Exits 1 on a mismatch.
  -x  Print the Major.Minor.Patch part of the version, without the prerelease suffix.
  -M  Print or increment the \`major\` version number.
  -m  Print or increment the \`minor\` version number.
  -p  Print or increment the \`patch\` version number.
        With '-i' on a prerelease version, '-p' releases it:  4.0.0-beta.2  ->  4.0.0

USAGE
}

version=4.0.0-beta.3

version_regex='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(alpha|beta|rc)\.(0|[1-9][0-9]*))?$'

config_file=../Sources/BranchSDK/BNCConfig.m
podspec_file=../BranchSDK.podspec
project_file=../BranchSDK.xcodeproj/project.pbxproj
framework_bundle_id=io.branch.BranchSDK

#  parse_version  <version>
#  Sets M, m, p, pre_label and pre_number from <version>. Returns 1 if <version> is malformed.
function parse_version() {
    if [[ ! "$1" =~ $version_regex ]]; then
        return 1
    fi
    M="${BASH_REMATCH[1]}"
    m="${BASH_REMATCH[2]}"
    p="${BASH_REMATCH[3]}"
    pre_label="${BASH_REMATCH[5]}"
    pre_number="${BASH_REMATCH[6]}"
}

#  framework_marketing_versions
#  Prints the MARKETING_VERSION of each build configuration whose bundle identifier is $framework_bundle_id.
function framework_marketing_versions() {
    BUNDLE_ID="$framework_bundle_id" perl -0ne '
        while (/isa = XCBuildConfiguration;\s*buildSettings = \{(.*?)\n\t\t\t\};/sg) {
            my $settings = $1;
            next unless $settings =~ /PRODUCT_BUNDLE_IDENTIFIER = \Q$ENV{BUNDLE_ID}\E;/;
            print "$1\n" if $settings =~ /MARKETING_VERSION = ([^;]*);/;
        }' "$project_file"
}

#  check_files  <version>  <core_version>
#  Prints each mismatch between the source files and <version>. Returns 1 if there is any.
function check_files() {
    local failed=0 value values
    value=$(sed -n 's/.*BNC_SDK_VERSION.*@"\(.*\)".*/\1/p' "$config_file")
    if [[ "$value" != "$1" ]]; then
        echo ">>> Error: BNC_SDK_VERSION is '$value' in '$config_file', expected '$1'." 1>&2
        failed=1
    fi
    value=$(sed -n 's/^[[:space:]]*s\.version[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$podspec_file")
    if [[ "$value" != "$1" ]]; then
        echo ">>> Error: s.version is '$value' in '$podspec_file', expected '$1'." 1>&2
        failed=1
    fi
    values=$(framework_marketing_versions | sort -u | tr '\n' ' ')
    if [[ "$values" != "$2 " ]]; then
        echo ">>> Error: framework MARKETING_VERSION is '${values% }' in '$project_file', expected '$2'." 1>&2
        failed=1
    fi
    return $failed
}

if ! parse_version "$version"; then
    echo ">>> Error: Current version '$version' is not a valid version number." 1>&2
    exit 1
fi

if (( $# == 0 )); then
    echo "$version"
    exit 0
fi

scriptfile="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scriptfile="${scriptfile}"/$(basename "$0")
cd "$(dirname "$scriptfile")"

major=
minor=
patch=
increment=
update=
check=
core=
set_version=
new_version=

while getopts ":hciMmpvuxs:" option; do
    case "$option" in
    h)  usage; exit 0 ;;
    c)  check=true ;;
    i)  increment=true; update=true ;;
    s)  set_version=true; new_version="$OPTARG"; update=true ;;
    M)  major=true ;;
    m)  minor=true ;;
    p)  patch=true ;;
    u)  update=true ;;
    x)  core=true ;;
    v)  ;;
    :)  echo ">>> Error: Option '-$OPTARG' requires a version argument." 1>&2; exit 1 ;;
    ?)  echo ">>> Error: Unknown option '-$OPTARG'." 1>&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if (( $# > 0 )); then
    echo ">>> Error: Unexpected argument '$1'." 1>&2
    exit 1
fi

if [[ $set_version && $increment ]]; then
    echo ">>> Error: Options '-s' and '-i' cannot be used together." 1>&2
    exit 1
fi

if [[ $check && $update ]]; then
    echo ">>> Error: Option '-c' cannot be used with '-i', '-s' or '-u'." 1>&2
    exit 1
fi

for file in "$config_file" "$podspec_file" "$project_file"; do
    if [[ ! -f "$file" ]]; then
        echo ">>> Error: '$file' not found." 1>&2
        exit 1
    fi
done


if [[ $check ]]; then
    if ! check_files "$version" "$M.$m.$p"; then
        exit 1
    fi
    echo "Source files match version $version."
    exit 0
fi


if [[ $set_version ]]; then

    if ! parse_version "$new_version"; then
        echo ">>> Error: '$new_version' is not a valid version number." 1>&2
        echo ">>> Expected Major.Minor.Patch or Major.Minor.Patch-{alpha|beta|rc}.Number, e.g. 4.0.0-beta.3" 1>&2
        exit 1
    fi
    version="$new_version"
    echo "$version"

elif [[ $increment ]]; then

    if [[ $major ]]; then
        M=$((M + 1)); m=0; p=0; pre_label=
    elif [[ $minor ]]; then
        m=$((m + 1)); p=0; pre_label=
    elif [[ $patch ]]; then
        if [[ $pre_label ]]; then
            pre_label=
        else
            p=$((p + 1))
        fi
    elif [[ $pre_label ]]; then
        pre_number=$((pre_number + 1))
    else
        p=$((p + 1))
    fi

    version="$M.$m.$p"
    if [[ $pre_label ]]; then
        version="$version-$pre_label.$pre_number"
    fi
    echo "$version"

else

    #  Print the version or parts

    if   [[ $major ]]; then
        echo "$M"
    elif [[ $minor ]]; then
        echo "$m"
    elif [[ $patch ]]; then
        echo "$p"
    elif [[ $core ]]; then
        echo "$M.$m.$p"
    elif [[ ! $update ]]; then
        echo "$version"
    fi

fi


if [[ $update ]]; then

    core_version="$M.$m.$p"

    # Update the SDK version:
    sed -i '' -e "/BNC_SDK_VERSION/ {s/\".*\"/\"$version\"/; }" "$config_file"

    # Update the Podspec version:
    sed -i '' -e "/^[[:space:]]*s\.version[[:space:]]*=/ {s/\".*\"/\"$version\"/; }" "$podspec_file"

    # Update framework version. CFBundleShortVersionString only allows Major.Minor.Patch.
    BUNDLE_ID="$framework_bundle_id" CORE_VERSION="$core_version" perl -0pi -e '
        s{(isa = XCBuildConfiguration;\s*buildSettings = \{.*?\n\t\t\t\};)}{
            my $block = $1;
            $block =~ s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $ENV{CORE_VERSION};/g
                if $block =~ /PRODUCT_BUNDLE_IDENTIFIER = \Q$ENV{BUNDLE_ID}\E;/;
            $block;
        }gse' "$project_file"

    if ! check_files "$version" "$core_version"; then
        exit 1
    fi
fi


if [[ $increment || $set_version ]]; then
    # Update our version (Do this last. Updating a running bash script has undefined results.)
    sed -i '' -e "s/^version=.*$/version=$version/" "$scriptfile"; exit 0
fi
