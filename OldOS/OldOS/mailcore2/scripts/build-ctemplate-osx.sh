#!/bin/sh

pushd "`dirname "$0"`" > /dev/null
scriptpath="`pwd`"
popd > /dev/null

. "$scriptpath/include.sh/build-dep.sh"

url="https://github.com/dinhviethoa/ctemplate"
rev=b50f83f26ce3658889db1ae41b6a2d5874a3a10f
name="ctemplate-osx"
xcode_target="ctemplate"
xcode_project="ctemplate.xcodeproj"
library="libctemplate.a"
embedded_deps=""

build_git_osx
