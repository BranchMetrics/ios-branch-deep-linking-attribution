#!/bin/bash
set -euo pipefail

# check_build_environment.sh  -  Check that the development environment is set up for deployment.
#
# Edward Smith, January 2017


wasError=0


function checkApp() {
    local appname="$1"
    local apppath=$(./scripts/whichapp "$appname" 2>&1)
    if (( ${#apppath} == 0 )); then
        echo ">>> Error: The application $appname not installed." 1>&2
        wasError=1
    fi
}


function checkTool() {
    local appname="$1"
    local apppath=$(which "$appname")
    if (( ${#apppath} == 0 )); then
        echo ">>> Error: The tool '$appname' is not installed." 1>&2
        wasError=1
    fi
}


function checkVariable() {
    local v=$1
    if [ -z ${!v+x} ]; then
        echo ">>> Error: Bash variable '$v' is unset." 1>&2
        wasError=1
    fi
    local vval=${!v}
    if (( ${#vval} == 0 )); then
        echo ">>> Error: Bash variable '$v' is empty." 1>&2
        wasError=1
    fi
}

# Check Xcode
checkApp Xcode

# Check CocoaPods
checkTool pod

# Check Carthage
checkTool carthage

if [[ $wasError != 0 ]]; then
    echo ">>> Error: deploy-preflight failed." 1>&2
    exit 1
fi

