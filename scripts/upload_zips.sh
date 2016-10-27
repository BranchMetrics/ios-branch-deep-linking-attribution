#/bin/sh
set -euo pipefail

#  Upload the SDK and the TestBed to AWS.
#
#  The files can be downloaded from:
#  https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-SDK.zip
#  https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-TestBed.zip

echo 'Zipping Branch-iOS-SDK'
zip -rqy Branch-iOS-SDK.zip Branch-SDK/ Branch.framework/

echo 'Zipping Branch-iOS-TestBed'
zip -rqy Branch-iOS-TestBed.zip Branch-SDK/ Branch-TestBed/ Branch.framework/

echo 'Uploading Branch-iOS-SDK'
aws s3 cp --acl public-read Branch-iOS-SDK.zip s3://branchhost/

echo 'Uploading Branch-iOS-TestBed'
aws s3 cp --acl public-read Branch-iOS-TestBed.zip s3://branchhost/

echo 'Computing the checksums'
sh scripts/checksum.sh

echo 'Removing zip files'
rm Branch-iOS-SDK.zip Branch-iOS-TestBed.zip
