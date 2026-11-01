### Build on Linux ###

- Install the following debian packages:

```
sudo apt-get install libctemplate-dev libicu-dev libsasl2-dev libtidy-dev \
    uuid-dev libxml2-dev libglib2.0-dev autoconf automake libtool
```

- Grab and compile the latest of libetpan: https://github.com/dinhviethoa/libetpan

```
mkdir ~/libetpan
cd ~/libetpan
git clone --depth=1 https://github.com/dinhviethoa/libetpan
cd libetpan
./autogen.sh
make >/dev/null
sudo make install prefix=/usr >/dev/null
```

- Compile MailCore 2:

```
cd ~/mailcore2
mkdir build
cd build
cmake ..
make
```
