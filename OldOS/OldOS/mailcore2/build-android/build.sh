#!/bin/sh

build_version=4
package_name=mailcore2-android
ctemplate_build_version=3
cyrus_sasl_build_version=4
icu4c_build_version=3
libetpan_build_version=6
libxml2_build_version=3
tidy_html5_build_version=3
openssl_build_version=3

current_dir="`pwd`"

if test "x$ANDROID_NDK" = x ; then
  echo should set ANDROID_NDK before running this script.
  exit 1
fi

if test "x$ANDROID_SDK" = x ; then
  echo should set ANDROID_SDK before running this script.
  exit 1
fi

function download_dep {
    name="$1"
    version="$2"
    if test ! -f "$current_dir/third-party/$name-$version.zip" ; then
        if curl -f -O "http://d.etpan.org/mailcore2-deps/$name/$name-$version.zip" ; then
            unzip "$name-$version.zip"
        else
            echo Could not download $name-$version.zip
            exit 1
        fi
    fi
}

function build {
    rm -rf "$current_dir/obj"
  
    cd "$current_dir/jni"
    $ANDROID_NDK/ndk-build TARGET_PLATFORM=$ANDROID_PLATFORM TARGET_ARCH_ABI=$TARGET_ARCH_ABI \
        NDK_TOOLCHAIN_VERSION=4.9 \
        CTEMPLATE_PATH=$current_dir/third-party/ctemplate-android-$ctemplate_build_version \
        ICU4C_PATH=$current_dir/third-party/icu4c-android-$icu4c_build_version \
        LIBETPAN_PATH=$current_dir/third-party/libetpan-android-$libetpan_build_version \
        LIBXML2_PATH=$current_dir/third-party/libxml2-android-$libxml2_build_version \
        TIDY_HTML5_PATH=$current_dir/third-party/tidy-html5-android-$tidy_html5_build_version \
        OPENSSL_PATH=$current_dir/third-party/openssl-android-$openssl_build_version \
        CYRUS_SASL_PATH=$current_dir/third-party/cyrus-sasl-android-$cyrus_sasl_build_version

    mkdir -p "$current_dir/bin/jni/$TARGET_ARCH_ABI"
    cp "$current_dir/libs/$TARGET_ARCH_ABI/libMailCore.so" "$current_dir/bin/jni/$TARGET_ARCH_ABI"
    # cp "$ANDROID_NDK/sources/cxx-stl/llvm-libc++/libs/$TARGET_ARCH_ABI/libc++_shared.so" "$current_dir/bin/jni/$TARGET_ARCH_ABI"
    cp "$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.9/libs/$TARGET_ARCH_ABI/libgnustl_shared.so" "$current_dir/bin/jni/$TARGET_ARCH_ABI"
    rm -rf "$current_dir/obj"
    rm -rf "$current_dir/libs"
}

mkdir -p "$current_dir/cmake-build"
cd "$current_dir/cmake-build"
cmake -D ANDROID=1 ../..

mkdir -p "$current_dir/include"
cp -R "$current_dir/cmake-build/src/include/MailCore" "$current_dir/include"

mkdir -p "$current_dir/third-party"
cd "$current_dir/third-party"
download_dep "ctemplate-android" $ctemplate_build_version
download_dep "icu4c-android" $icu4c_build_version
download_dep "libetpan-android" $libetpan_build_version
download_dep "libxml2-android" $libxml2_build_version
download_dep "tidy-html5-android" $tidy_html5_build_version
download_dep "openssl-android" $openssl_build_version
download_dep "cyrus-sasl-android" $cyrus_sasl_build_version

# Start building.
ANDROID_PLATFORM=android-16
archs="armeabi armeabi-v7a x86"
for arch in $archs ; do
  TARGET_ARCH_ABI=$arch
  build
done
ANDROID_PLATFORM=android-21
archs="arm64-v8a"
for arch in $archs ; do
  TARGET_ARCH_ABI=$arch
  build
done

ANDROID_PLATFORM=android-16
cd "$current_dir/../src/java"
mkdir -p "$current_dir/bin"
javac -d "$current_dir/bin" -source 1.6 -target 1.6 -classpath $ANDROID_SDK/platforms/$ANDROID_PLATFORM/android.jar com/libmailcore/*.java
cd "$current_dir/bin"
jar cf classes.jar .
rm -rf "$current_dir/bin/com"
mkdir -p res
sed -e "s/android:versionCode=\"1\"/android:versionCode=\"$build_version\"/" "$current_dir/AndroidManifest.xml" > "$current_dir/bin/AndroidManifest.xml"
zip -qry "$current_dir/$package_name-$build_version.aar" .

rm -rf "$current_dir/bin"
