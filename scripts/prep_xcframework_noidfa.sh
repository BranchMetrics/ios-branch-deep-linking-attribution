#!/bin/bash
set -euo pipefail

# checksum file
scheme='xcframework-noidfa'
checksum_file=checksum_noidfa.txt
zip_file=Branch_noidfa.zip

scriptname=$(basename "${BASH_SOURCE[0]}")
scriptpath="${BASH_SOURCE[0]}"
scriptpath=$(cd "$(dirname "${scriptpath}")" && pwd)

# Build
echo "Building BranchSDK.xcframework"
xcodebuild -scheme $scheme

# Move to build folder
cd ${scriptpath}/../build

# Zip the SDK files
echo "Zipping BranchSDK.xcframework"
zip -rqy $zip_file BranchSDK.xcframework/

# Checksum the zip file
echo "Creating BranchSDK checksum"
echo '#checksum for BranchSDK on Github' > "$checksum_file"
shasum $zip_file >> $checksum_file

# Move zip file and checksum
mv $zip_file ..
mv $checksum_file ..

# Remove source frameworks
echo "Cleaning up"
rm -rf BranchSDK.xcframework
