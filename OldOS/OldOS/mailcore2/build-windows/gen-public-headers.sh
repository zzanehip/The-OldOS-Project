#!/bin/sh

files=""

list_headers()
{
  local filename="$1"
  
  if echo $files | grep "\[$filename\]" >/dev/null ; then
    return
  fi
  
  local path="`find . -name $filename`"
  echo $path | sed 's/^.\//src\//' | sed 's/\//\\/g'
  files="$files[$filename]"
  subfilenames="`grep '#include <MailCore/' "$path" | sed 's/^#include <MailCore\/\(.*\)>$/\1/'`"
  subfilenames+=" "
  subfilenames+="`grep '#import <MailCore/' "$path" | sed 's/^#import <MailCore\/\(.*\)>$/\1/'`"
  for include_dir in $subfilenames ; do
    list_headers $include_dir
  done
}

cd ../src
list_headers MailCore.h
