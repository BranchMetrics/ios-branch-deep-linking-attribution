#!/bin/bash
set -euo pipefail

# checksum file
scheme='Branch-static-xcframework-noidfa'
checksum_file=checksum_static_noidfa.txt
zip_file=Branch_static_noidfa.zip

scriptname=$(basename "${BASH_SOURCE[0]}")
scriptpath="${BASH_SOURCE[0]}"
scriptpath=$(cd "$(dirname "${scriptpath}")" && pwd)
cd ${scriptpath}/../carthage-files

# Build
echo "Building Branch.xcframework"
xcodebuild -scheme $scheme

# Move to build folder
cd ${scriptpath}/../carthage-files/build

# Zip the SDK files
echo "Zipping Branch.xcframework and static library"
zip -rqy $zip_file Branch.xcframework/

# Checksum the zip file
echo "Creating Branch checksum"
echo '#checksum for Branch on Github' > "$checksum_file"
shasum $zip_file >> $checksum_file

# Move zip file and checksum
mv $zip_file ..
mv $checksum_file ..

# Remove source frameworks
echo "Cleaning up"
rm -rf Branch.xcframework
