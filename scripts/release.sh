#!/bin/bash

[ $# -eq 0 ] && { echo "Usage: $0 1.0.0"; exit 1; }

SCRIPT_DIR=$(cd "$(dirname $0)" && pwd)
PROJECT_DIR=$SCRIPT_DIR/..
SED_TMP_LOC=$PROJECT_DIR/sed.tmp
CHANGELOG_LOC=$PROJECT_DIR/ChangeLog.md
PODSPEC_LOC=$PROJECT_DIR/Branch.podspec
BNCCONFIG_LOC=$SCRIPT_DIR/../Branch-SDK/Branch-SDK/BNCConfig.h
BRANCHM_LOC=$SCRIPT_DIR/../Branch-SDK/Branch-SDK/Branch.m

# Replace version numbers. Note, with sed, we can't write to the same file we read, so we make a temp one for the operation, then immediately replace it.
sed 's/  s.version.*$/  s.version          = "'$1'"/' <$PODSPEC_LOC >$SED_TMP_LOC && mv $SED_TMP_LOC $PODSPEC_LOC
sed 's/#define SDK_VERSION.*$/#define SDK_VERSION             @"'$1'"/' <$BNCCONFIG_LOC >$SED_TMP_LOC && mv $SED_TMP_LOC $BNCCONFIG_LOC

# Update Fabric Kit Display version automatically
perl -0pi -e "s/\+ \(NSString \*\)kitDisplayVersion {.*/+ (NSString \*)kitDisplayVersion {\n\treturn \@\""$1"\";\n}\n\n\@end/sg" $BRANCHM_LOC

# Set up the header for the release in the ChangeLog.
sed 's/Branch iOS SDK change log/Branch iOS SDK change log\
\
- v'$1'\
  */' <$CHANGELOG_LOC >$SED_TMP_LOC && mv $SED_TMP_LOC $CHANGELOG_LOC

# Prompt for editor input for ChangeLog. 
vim +4 +star $CHANGELOG_LOC

# Build the framework
sh $SCRIPT_DIR/build_framework.sh

# Commit and tag
git add .
git commit -m "Updates for $1 release."
git tag $1
git push --tags origin master

# Release to CocoaPods
pod trunk push $PODSPEC_LOC

# Upload to S3
sh $SCRIPT_DIR/upload_zips.sh

# Prompt for SDK Releases Group post
open https://groups.google.com/forum/#!newtopic/branch-sdk-releases
