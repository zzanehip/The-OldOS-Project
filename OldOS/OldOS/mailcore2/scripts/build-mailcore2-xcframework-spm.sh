#!/bin/sh

# Create XCFramework
cd "$(dirname "$0")"
./build-mailcore2-xcframework.sh

cd ../

MAILCORE_DIR="`pwd`"
BUILD_DIR="$MAILCORE_DIR/.build"
DATE="`date +"%Y-%m-%d"`"
FRAMEWORK_NAME="MailCore2.xcframework"
ARCHIVE_NAME="MailCore2-$DATE.xcframework.zip"
MANIFEST_PATH="$MAILCORE_DIR/Package.swift"
BASE_URL="https://github.com/MailCore/mailcore2/raw/master/bin"
FULL_URL="$BASE_URL/$ARCHIVE_NAME"
SUCCESS_MESSAGE="
-------------------
File saved at: $BUILD_DIR/$ARCHIVE_NAME
SPM Update Instructions:
1. Upload new file to $FULL_URL
2. Update Package.swift with new URL and checksum
3. Create new release
-------------------"

# Make sure xcframework export was successful
if [[ -d "$BUILD_DIR/$FRAMEWORK_NAME" ]]; then
    cd $BUILD_DIR
    
    # Clear previous archive
    rm "$BUILD_DIR/$ARCHIVE_NAME"

    # Prepare for Distribution
    zip -r -X "$ARCHIVE_NAME" "$FRAMEWORK_NAME"
    CHECKSUM="`swift package compute-checksum "$ARCHIVE_NAME"`"

    # Update Package.swift manifest file
    sed -i.bak "s~url: \"\(.*\)\"~url: \"$FULL_URL\"~g" $MANIFEST_PATH
    sed -i.bak "s~checksum: \"\(.*\)\"~checksum: \"$CHECKSUM\"~g" $MANIFEST_PATH
    rm $MANIFEST_PATH.bak
    
    echo "$SUCCESS_MESSAGE"
fi


