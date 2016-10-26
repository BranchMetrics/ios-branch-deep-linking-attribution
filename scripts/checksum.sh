#!/bin/sh
checksum_file=checksum
sdk_archive=Branch-iOS-SDK.zip
testbed_archive=Branch-iOS-TestBed.zip

echo '#checksum for Branch-iOS-SDK found at https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-SDK.zip' > $checksum_file
shasum $sdk_archive >> $checksum_file
echo '#checksum for Branch-iOS-TestBed found at https://s3-us-west-1.amazonaws.com/branchhost/Branch-iOS-TestBed.zip' >> $checksum_file
shasum $testbed_archive >> $checksum_file

git checkout master
git add $checksum_file
git commit -m 'compute checksum'
git push

echo 'Pushed Checksum to master'
