#/bin/sh

zip Branch-iOS-SDK.zip Branch-SDK/ Branch.framework/
zip Branch-iOS-TestBed.zip Branch-SDK/ Branch-TestBed/ Branch.framework/

aws s3 cp Branch-iOS-SDK.zip s3://branchhost/
aws s3 cp Branch-iOS-TestBed.zip s3://branchhost/
