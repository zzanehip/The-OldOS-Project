#!/bin/bash

if test "x$ANDROID_SDK" = x ; then
  echo should set ANDROID_SDK before running this script.
  exit 1
fi

TARGET_PLATFORM=android-21

echo Building Java
javac -classpath $ANDROID_SDK/platforms/$TARGET_PLATFORM/android.jar com/libmailcore/*.java

echo Creating headers

cd com/libmailcore
list="`echo com/libmailcore/*.java`"
cd ../..

for name in $list; do
    name="`echo $name|sed -e 's/\.java//'|sed -e 's/\//\./g'`"
    javah -d native -jni $name
done

rm com/libmailcore/*.class
