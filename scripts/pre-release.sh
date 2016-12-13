#!/bin/bash

# if [ `git status -bs` != "## QA...origin/QA" ]; then
#     echo ">>> Error:  Must be on the QA branch." 1>&2
#     exit 1
# fi

pod lib lint Branch.podspec --verbose
