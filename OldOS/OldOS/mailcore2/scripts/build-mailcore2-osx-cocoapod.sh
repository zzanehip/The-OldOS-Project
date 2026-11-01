#!/bin/sh

pushd "`dirname "$0"`" > /dev/null
scriptpath="`pwd`"
popd > /dev/null

. "$scriptpath/include.sh/build-dep-cocoapod.sh"

name="mailcore2-osx"
xcode_target="static mailcore2 osx"
xcode_project="mailcore2.xcodeproj"
library="libMailCore.a"
embedded_deps="ctemplate-osx libetpan-osx"
build_mailcore=1
TOPDIR="$scriptpath/.."

build_git_osx
