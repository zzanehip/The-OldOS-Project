#!/bin/sh

pushd "`dirname "$0"`" > /dev/null
scriptpath="`pwd`"
popd > /dev/null

. "$scriptpath/include.sh/build-dep.sh"

url="https://github.com/mailcore/mailcore2.git"
rev=897b4a23d27984b06dd2caf441268ef4b6ad9d67
name="mailcore2-framework-osx"
xcode_target="mailcore osx"
xcode_project="mailcore2.xcodeproj"
library="MailCore.framework"
embedded_deps="ctemplate-osx libetpan-osx"

build_git_osx
