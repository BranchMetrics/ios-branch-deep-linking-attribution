#!/bin/sh

export PROJECT_DIR=Branch-TestBed
export LIBRARY_BINARY_NAME=libBranch.a
export BUILD_DIR=build
export XCODE_BUILD_TARGET=Branch
export CONFIGURATION=Release
export FRAMEWORK_DIR=Branch.framework
export FRAMEWORK_BINARY_NAME=Branch

function xcode_build_target() {
    echo "Compiling for platform ${1}"

    xcodebuild \
        -target $XCODE_BUILD_TARGET \
        -sdk $1 \
        -configuration $2 \
        clean build \
        || die "Xcode build failed for platform: ${1}"
}

# Compile static libraries

cd $PROJECT_DIR

rm -rf $BUILD_DIR

xcode_build_target "iphoneos" $CONFIGURATION
xcode_build_target "iphonesimulator" $CONFIGURATION

cd ..

# Merge static libraries into a universal static library

lipo \
    -create \
        $PROJECT_DIR/$BUILD_DIR/$CONFIGURATION-iphoneos/$LIBRARY_BINARY_NAME \
        $PROJECT_DIR/$BUILD_DIR/$CONFIGURATION-iphonesimulator/$LIBRARY_BINARY_NAME \
    -output \
        $PROJECT_DIR/$BUILD_DIR/$LIBRARY_BINARY_NAME \
    || die "lipo failed -- could not create universal static library"


# # Create .framework

rm -rf $FRAMEWORK_DIR

mkdir -p $FRAMEWORK_DIR
mkdir -p $FRAMEWORK_DIR/Versions
mkdir -p $FRAMEWORK_DIR/Versions/A
mkdir -p $FRAMEWORK_DIR/Versions/A/Headers

cp $PROJECT_DIR/$BUILD_DIR/$CONFIGURATION-iphoneos/Headers/* $FRAMEWORK_DIR/Versions/A/Headers/
cp $PROJECT_DIR/$BUILD_DIR/$LIBRARY_BINARY_NAME $FRAMEWORK_DIR/Versions/A/$FRAMEWORK_BINARY_NAME

cd $FRAMEWORK_DIR
ln -s Versions/Current/Headers Headers
ln -s Versions/Current/$FRAMEWORK_BINARY_NAME $FRAMEWORK_BINARY_NAME
cd Versions
ln -s A Current
