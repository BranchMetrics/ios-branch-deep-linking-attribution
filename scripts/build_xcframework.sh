#!/bin/sh
# BranchSDK.xcodeproj xcframework target runs this script

# config
IOS_PATH="./build/ios/ios.xcarchive"
IOS_SIM_PATH="./build/ios/ios_sim.xcarchive"
TVOS_PATH="./build/tvos/tvos.xcarchive"
TVOS_SIM_PATH="./build/tvos/tvos_sim.xcarchive"
CATALYST_PATH="./build/catalyst/catalyst.xcarchive"
XCFRAMEWORK_PATH="./build/BranchSDK.xcframework"
XCFRAMEWORK_PATH_SIGNED="./build/signedFramework/"
XCFRAMEWORK_PATH_dSYM="./build/dSymFramework/BranchSDK.xcframework"

# delete previous build
rm -rf "./build" 

# build iOS framework
xcodebuild archive \
    -scheme BranchSDK \
    -archivePath "${IOS_PATH}" \
    -sdk iphoneos \
    SKIP_INSTALL=NO

# build iOS simulator framework
xcodebuild archive \
    -scheme BranchSDK \
    -archivePath "${IOS_SIM_PATH}" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO

 # build tvOS framework
 xcodebuild archive \
     -scheme BranchSDK-tvOS \
     -archivePath "${TVOS_PATH}" \
     -sdk appletvos \
     SKIP_INSTALL=NO

 # build tvOS simulator framework
 xcodebuild archive \
     -scheme BranchSDK-tvOS \
     -archivePath "${TVOS_SIM_PATH}" \
     -sdk appletvsimulator \
     SKIP_INSTALL=NO
    
# build Catalyst framework
 xcodebuild archive \
     -scheme BranchSDK \
     -archivePath "${CATALYST_PATH}" \
     -destination 'platform=macOS,arch=x86_64,variant=Mac Catalyst' \
     SKIP_INSTALL=NO

# package frameworks
xcodebuild -create-xcframework \
    -framework "${IOS_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${IOS_SIM_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${TVOS_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${TVOS_SIM_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -framework "${CATALYST_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -output "${XCFRAMEWORK_PATH}"

# create signed binary
mkdir -p "${XCFRAMEWORK_PATH_SIGNED}"
cp -rf "${XCFRAMEWORK_PATH}" "${XCFRAMEWORK_PATH_SIGNED}"
codesign --deep --timestamp -s  "Apple Distribution: Branch Metrics, Inc. (R63EM248DP)" "${XCFRAMEWORK_PATH_SIGNED}/BranchSDK.xcframework"

# package framework with dSyms
xcodebuild -create-xcframework \
    -framework "${IOS_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -debug-symbols "$(pwd)/build/ios/ios.xcarchive/dSYMs/BranchSDK.framework.dSYM"\
    -framework "${IOS_SIM_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -debug-symbols "$(pwd)/build/ios/ios_sim.xcarchive/dSYMs/BranchSDK.framework.dSYM"\
    -framework "${TVOS_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -debug-symbols "$(pwd)/build/tvos/tvos.xcarchive/dSYMs/BranchSDK.framework.dSYM"\
    -framework "${TVOS_SIM_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -debug-symbols "$(pwd)/build/tvos/tvos_sim.xcarchive/dSYMs/BranchSDK.framework.dSYM"\
    -framework "${CATALYST_PATH}/Products/Library/Frameworks/BranchSDK.framework" \
    -debug-symbols "$(pwd)/build/catalyst/catalyst.xcarchive/dSYMs/BranchSDK.framework.dSYM"\
    -output "${XCFRAMEWORK_PATH_dSYM}"
