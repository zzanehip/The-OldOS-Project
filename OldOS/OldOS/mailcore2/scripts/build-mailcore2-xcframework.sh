#!/bin/sh

cd "$(dirname "$0")"
cd ../

MAILCORE_DIR="`pwd`"
BUILD_DIR="$MAILCORE_DIR/.build"
FRAMEWORK_NAME="MailCore2.xcframework"

mkdir $BUILD_DIR
rm -rf "$BUILD_DIR/$FRAMEWORK_NAME"

cd build-mac

# Build Mac Archive
xcodebuild archive -scheme "mailcore osx" \
    -arch "x86_64" \
    -archivePath "$BUILD_DIR/mailcore2.macOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
# Build iOS Archive
xcodebuild archive -scheme "mailcore ios" \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/mailcore2.iOS.xcarchive" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build iOS Simulator Archive
xcodebuild archive -scheme "mailcore ios" \
    -arch "x86_64" \
    -archivePath "$BUILD_DIR/mailcore2.iOS-Simulator.xcarchive" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build Mac Catalyst Archive - UNCOMMENT ONCE MAC CATALYST BUILDING IS FIXED
#xcodebuild archive -scheme "mailcore ios" \
#    -destination "platform=macOS,variant=Mac Catalyst" \
#    -archivePath "$BUILD_DIR/mailcore2.macOS-Catalyst.xcarchive" \
#    -sdk ???? \
#    SKIP_INSTALL=NO \
#    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

cd $BUILD_DIR

# Create Combined XCArchive - REMOVE ONCE MAC CATALYST BUILDING IS FIXED
xcodebuild -create-xcframework \
	-framework "mailcore2.macOS.xcarchive/Products/Frameworks/MailCore.framework" \
	-framework "mailcore2.iOS-Simulator.xcarchive/Products/Frameworks/MailCore.framework" \
	-framework "mailcore2.iOS.xcarchive/Products/Frameworks/MailCore.framework" \
	-output "$FRAMEWORK_NAME"

# Create Combine XCArchive - UNCOMMENT ONCE MAC CATALYST BUILDING IS FIXED
# xcodebuild -create-xcframework \
# 	-framework "$BUILD_DIR/mailcore2.macOS.xcarchive/Products/Frameworks/MailCore.framework" \
# 	-framework "$BUILD_DIR/mailcore2.iOS-Simulator.xcarchive/Products/Frameworks/MailCore.framework" \
# 	-framework "$BUILD_DIR/mailcore2.iOS.xcarchive/Products/Frameworks/MailCore.framework" \
# 	-framework "$BUILD_DIR/mailcore2.macOS-Catalyst.xcarchive/Products/Frameworks/MailCore.framework"
# 	-output "$BUILD_DIR/mailcore2.xcframework"

# Clean Up
rm -rf "$BUILD_DIR/mailcore2.macOS.xcarchive"
rm -rf "$BUILD_DIR/mailcore2.iOS-Simulator.xcarchive"
rm -rf "$BUILD_DIR/mailcore2.iOS.xcarchive"
