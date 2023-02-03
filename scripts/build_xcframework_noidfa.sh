#!/bin/sh
# BranchSDK.xcodeproj xcframework-noidfa target runs this script

# config
IOS_PATH="./build/ios/ios.xcarchive"
IOS_SIM_PATH="./build/ios/ios_sim.xcarchive"
TVOS_PATH="./build/tvos/tvos.xcarchive"
TVOS_SIM_PATH="./build/tvos/tvos_sim.xcarchive"
CATALYST_PATH="./build/catalyst/catalyst.xcarchive"
XCFRAMEWORK_PATH="./build/BranchSDK.xcframework"

# delete previous build
rm -rf "./build" 

# build iOS framework
xcodebuild archive \
    -scheme BranchSDK \
    -archivePath "${IOS_PATH}" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS='${inherited} BRANCH_EXCLUDE_IDFA_CODE=1'

# build iOS simulator framework
xcodebuild archive \
    -scheme BranchSDK \
    -archivePath "${IOS_SIM_PATH}" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS='${inherited} BRANCH_EXCLUDE_IDFA_CODE=1'

 # build tvOS framework
 xcodebuild archive \
     -scheme BranchSDK-tvOS \
     -archivePath "${TVOS_PATH}" \
     -sdk appletvos \
     SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS='${inherited} BRANCH_EXCLUDE_IDFA_CODE=1'

 # build tvOS simulator framework
 xcodebuild archive \
     -scheme BranchSDK-tvOS \
     -archivePath "${TVOS_SIM_PATH}" \
     -sdk appletvsimulator \
     SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS='${inherited} BRANCH_EXCLUDE_IDFA_CODE=1'
    
# build Catalyst framework
 xcodebuild archive \
     -scheme BranchSDK \
     -archivePath "${CATALYST_PATH}" \
     -destination 'platform=macOS,arch=x86_64,variant=Mac Catalyst' \
     SKIP_INSTALL=NO \
    GCC_PREPROCESSOR_DEFINITIONS='${inherited} BRANCH_EXCLUDE_IDFA_CODE=1'

# package frameworks
xcodebuild -create-xcframework \
    -framework "${IOS_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${IOS_SIM_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${TVOS_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${TVOS_SIM_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${CATALYST_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -output "${XCFRAMEWORK_PATH}"

    
    
