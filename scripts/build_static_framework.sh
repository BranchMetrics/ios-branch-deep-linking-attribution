#!/bin/bash
set -euo pipefail

scriptname=$(basename "${BASH_SOURCE[0]}")
scriptpath="${BASH_SOURCE[0]}"
scriptpath=$(cd "$(dirname "${scriptpath}")" && pwd)
cd ${scriptpath}/../carthage-files

# Build
echo "Building Branch.xcframework"
xcodebuild -scheme 'Branch-static-xcframework'

# Move to build folder
cd ${scriptpath}/../carthage-files/build

# Zip the SDK files
echo "Zipping static Branch.xcframework"
zip -rqy Branch_static.zip Branch.xcframework/

# Checksum the zip file
echo "Creating Branch_static.zip checksum"
checksum_file=checksum_static

echo '#checksum for Branch_static.zip on Github' > "$checksum_file"
shasum Branch_static.zip >> $checksum_file

# Move zip file and checksum
mv Branch_static.zip ..
mv checksum_static ..

# Remove source frameworks
echo "Cleaning up"
rm -rf Branch.xcframework
