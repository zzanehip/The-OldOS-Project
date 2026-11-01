#!/bin/sh

pushd "`dirname "$0"`" > /dev/null
scriptpath="`pwd`"
popd > /dev/null

. "$scriptpath/include.sh/build-dep-cocoapod.sh"

name="mailcore2-ios"
xcode_target="static mailcore2 ios"
xcode_project="mailcore2.xcodeproj"
library="libMailCore-ios.a"
embedded_deps="ctemplate-ios libetpan-ios libsasl-ios tidy-html5-ios"
build_mailcore=1
TOPDIR="$scriptpath/.."

build_git_ios
