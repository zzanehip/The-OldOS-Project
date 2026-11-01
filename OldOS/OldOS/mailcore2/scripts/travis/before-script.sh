#!/bin/sh
set -e

if test x"`uname`" = xDarwin ; then
  sudo systemsetup -settimezone America/Los_Angeles
  brew update || brew update || :
  brew uninstall xctool && brew install --HEAD xctool
  if ! which cmake >/dev/null ; then
    brew install cmake
  fi
elif test x"`uname`" = xLinux ; then
  git clone --depth=1 https://github.com/dinhviethoa/libetpan
  cd libetpan
  ./autogen.sh
  make >/dev/null
  sudo make install >/dev/null
  cd ..
  git clone --depth=1 https://github.com/dinhviethoa/ctemplate
  cd ctemplate
  ./autogen.sh
  ./configure
  make >/dev/null
  sudo make install >/dev/null
  cd ..
  curl -O https://www.kernel.org/pub/linux/utils/util-linux/v2.27/util-linux-2.27.1.tar.xz
  tar xf util-linux-2.27.1.tar.xz
  cd util-linux-2.27.1
  ./configure
  make libuuid.la
  sudo make install-uuidincHEADERS
  sudo cp .libs/libuuid.so /usr/lib
  cd ..

  sudo apt-get install libicu-dev
  sudo apt-get install libtidy-dev
  sudo apt-get install libxml2-dev
fi

