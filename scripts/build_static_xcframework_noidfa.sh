#!/bin/sh
# BranchSDK.xcodeproj static-xcframework-noidfa target runs this script

# config
IOS_PATH="./build/ios/ios.xcarchive"
IOS_SIM_PATH="./build/ios/ios_sim.xcarchive"
CATALYST_PATH="./build/catalyst/catalyst.xcarchive"
XCFRAMEWORK_PATH="./build/BranchSDK.xcframework"

# delete previous build
rm -rf "./build"

# build iOS framework
xcodebuild archive \
    -scheme BranchSDK-static \
    -archivePath "${IOS_PATH}" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS='${inherited} BRANCH_EXCLUDE_IDFA_CODE=1'

# build iOS simulator framework
xcodebuild archive \
    -scheme BranchSDK-static \
    -archivePath "${IOS_SIM_PATH}" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS='${inherited} BRANCH_EXCLUDE_IDFA_CODE=1'
    
# build Catalyst framework
 xcodebuild archive \
     -scheme BranchSDK-static \
     -archivePath "${CATALYST_PATH}" \
     -destination 'platform=macOS,arch=x86_64,variant=Mac Catalyst' \
     SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS='${inherited} BRANCH_EXCLUDE_IDFA_CODE=1'

# package frameworks
xcodebuild -create-xcframework \
    -framework "${IOS_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${IOS_SIM_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${CATALYST_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -output "${XCFRAMEWORK_PATH}"

# build a static fat library from the xcframework
# this is used by xamarin
TEMP_LIB_PATH="./build/BranchSDK.sim"
LIBRARY_PATH="./build/BranchSDK.a"

# create simulator library without m1
lipo -output "${TEMP_LIB_PATH}" -remove arm64 "${XCFRAMEWORK_PATH}/ios-arm64_x86_64-simulator/BranchSDK.framework/BranchSDK"

# create a fat static library
lipo "${XCFRAMEWORK_PATH}/ios-arm64/BranchSDK.framework/BranchSDK" "${TEMP_LIB_PATH}" -create -output "${LIBRARY_PATH}"
    
