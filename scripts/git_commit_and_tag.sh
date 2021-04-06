#!/bin/bash
set -euo pipefail

# git_commit_and_tag.sh  -  Commit and push the current git changes.  Create a version tag and push to master.
#
# Edward Smith, January 2017

scriptfile="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scriptfile="${scriptfile}"/$(basename "$0")
cd $(dirname "$scriptfile")/..

git_branch=$(git symbolic-ref --short HEAD)
version=$(./scripts/version.sh)

echo ">>> Merging and pushing '$git_branch' to master..." 1>&2

# Tag and merge the release to master:

git checkout master
git pull
git merge -m "Merge ${git_branch}." origin "${git_branch}"
(git commit || true)
git tag "${version}"
git push
git push --tags origin master

# Update staging from master:
git checkout staging
git pull
git pull origin master
git push
