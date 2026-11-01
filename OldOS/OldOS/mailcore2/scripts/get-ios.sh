#!/bin/sh

pushd "`dirname "$0"`" > /dev/null
scriptpath="`pwd`"
popd > /dev/null

. "$scriptpath/include.sh/build-dep.sh"

deps="ctemplate-ios libetpan-ios tidy-html5-ios"
for dep in $deps ; do
  name="$dep"
  get_prebuilt_dep
done

deps+=" libsasl-ios"
if test "x$CONFIGURATION_BUILD_DIR" != x ; then
  mkdir -p "$CONFIGURATION_BUILD_DIR"
  cd "$scriptpath/../Externals"
  for dep in $deps ; do
    if test -d "$dep" ; then
      if test -d "$dep"/lib ; then
        rsync -a "$dep"/lib/ "$CONFIGURATION_BUILD_DIR"
      fi
      if test -d "$dep"/include ; then
        rsync -a "$dep"/include/ "$CONFIGURATION_BUILD_DIR/include/"
      fi
    fi
  done
fi
