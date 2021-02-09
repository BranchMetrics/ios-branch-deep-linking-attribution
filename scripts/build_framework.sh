#!/bin/bash
set -euo pipefail

scriptname=$(basename "${BASH_SOURCE[0]}")
scriptpath="${BASH_SOURCE[0]}"
scriptpath=$(cd "$(dirname "${scriptpath}")" && pwd)
cd ${scriptpath}/../carthage-files

# Build
echo "Building Branch.xcframework"
xcodebuild -scheme 'Branch-xcframework'

# Move to build folder
cd ${scriptpath}/../carthage-files/build

# Zip the SDK files
echo "Zipping Branch.xcframework"
zip -rqy Branch.zip Branch.xcframework/

# Checksum the zip file
echo "Creating Branch.zip checksum"
checksum_file=checksum

echo '#checksum for Branch.zip on Github' > "$checksum_file"
shasum Branch.zip >> $checksum_file

# Move zip file and checksum
mv Branch.zip ..
mv checksum ..

# Remove source frameworks
echo "Cleaning up"
rm -rf Branch.xcframework
