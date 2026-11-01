## MailCore 2 on Windows ##

All the provided binaries are compiled in release mode.
For the debug mode, you need to download the repositories and compile them.

### Binary ###

In case you just need a binary build of MailCore 2:
- [MailCore 2](http://d.etpan.org/mailcore2-deps/mailcore2-win32/)

Also, you'll need all the dependencies, download the most recent binary builds in:

- [CTemplate](http://d.etpan.org/mailcore2-deps/ctemplate-win32/)
- [libEtPan](http://d.etpan.org/mailcore2-deps/libetpan-win32/)
- [Cyrus SASL](http://d.etpan.org/mailcore2-deps/cyrus-sasl-win32/)
- [LibXML 2](http://d.etpan.org/mailcore2-deps/libxml2-win32/)
- [Tidy HTML5](http://d.etpan.org/mailcore2-deps/tidy-html5-win32/)
- [zlib](http://d.etpan.org/mailcore2-deps/zlib-win32/)
- [ICU, OpenSSL and pthread for win32](http://d.etpan.org/mailcore2-deps/misc-win32/)

### Build using Visual Studio 2013 ###

You'll need all the dependencies, download the most recent binary builds in:

- [CTemplate](http://d.etpan.org/mailcore2-deps/ctemplate-win32/)
- [libEtPan](http://d.etpan.org/mailcore2-deps/libetpan-win32/)
- [Cyrus SASL](http://d.etpan.org/mailcore2-deps/cyrus-sasl-win32/)
- [LibXML 2](http://d.etpan.org/mailcore2-deps/libxml2-win32/)
- [Tidy HTML5](http://d.etpan.org/mailcore2-deps/tidy-html5-win32/)
- [zlib](http://d.etpan.org/mailcore2-deps/zlib-win32/)
- [icu4c, OpenSSL and pthread for win32](http://d.etpan.org/mailcore2-deps/misc-win32/)

#### Instructions for CTemplate, libEtPan,Cyrus SASL, LibXML 2, Tidy HTML5 and zlib ####

- copy `include`, `lib` and `lib64` folders to `mailcore2/Externals`.

#### icu4c win32 ####

- copy `bin`, `include` and `lib` folders to `mailcore2/Externals`.

#### icu4c win64 ####

- copy `bin64`, `include` and `lib64` folders to `mailcore2/Externals`.

#### openssl ####

- copy `bin`, `bin64`, `include`, `lib` and `lib64` to `mailcore2/Externals`.

#### pthread ####

- In `Pre-built.2`, copy `dll`, `include` and `lib` to `mailcore2/Externals`.

As a result, in `Externals` folder, you should have the following folders: `include`, `lib`, `lib64`, `bin`, `bin64` and `dll`.

In `mailcore2/build-windows/mailcore2`, using Visual Studio 2013, open `mailcore2.sln`.
Then, build.

Public headers will be located in `mailcore2/build-windows/include`.
