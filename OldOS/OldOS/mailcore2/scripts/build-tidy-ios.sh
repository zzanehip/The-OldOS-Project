#!/bin/sh

pushd "`dirname "$0"`" > /dev/null
scriptpath="`pwd`"
popd > /dev/null

. "$scriptpath/include.sh/build-dep.sh"

url="https://github.com/dinhviethoa/tidy-html5"
rev=71aaa8669c664447743bba73e07d70c291548dca
name="tidy-html5-ios"
xcode_target="tidy"
xcode_project="Tidy.xcodeproj"
library="libtidy.a"
embedded_deps=""

build_git_ios
