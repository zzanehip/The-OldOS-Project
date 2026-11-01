#!/bin/sh

pushd "`dirname "$0"`" > /dev/null
scriptpath="`pwd`"
popd > /dev/null

. "$scriptpath/include.sh/build-dep.sh"

url="https://github.com/dinhviethoa/ctemplate"
rev=2c6ff9ae7d0ae1b973e57dd19859b95282776194
name="ctemplate-ios"
xcode_target="ctemplate-ios"
xcode_project="ctemplate.xcodeproj"
library="libctemplate-ios.a"
embedded_deps=""

build_git_ios
