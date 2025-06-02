#!/usr/bin/bash
pushd /tmp

BASE_CFLAGS="-march=native -Ofast -fno-plt"
BASE_LDFLAGS="-s -Wl,-O2,--gc-sections"
CLANG_CFLAGS="$BASE_CFLAGS -flto=full"
CLANG_LDFLAGS="$BASE_LDFLAGS -fuse-ld=lld"
GCC_CFLAGS="$BASE_CFLAGS -flto -flto-partition=none -fipa-pta -fno-semantic-interposition -fdevirtualize-at-ltrans -ffunction-sections -fdata-sections"
GCC_LDFLAGS="$BASE_LDFLAGS -fuse-linker-plugin"

# Build zlib-ng
git clone https://github.com/zlib-ng/zlib-ng
pushd zlib-ng
git checkout $(git describe --abbrev=0 --tags)
mkdir build
pushd build
cmake .. \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_C_FLAGS_RELEASE="$CLANG_CFLAGS" \
    -DCMAKE_SHARED_LINKER_FLAGS="$CLANG_LDFLAGS" \
    -DZLIB_COMPAT=ON \
    -DZLIB_ENABLE_TESTS=OFF \
    -DWITH_NATIVE_INSTRUCTIONS=ON \
    -DWITH_RUNTIME_CPU_DETECTION=OFF \
    -DWITH_GTEST=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DWITH_SANITIZER=OFF
make -j$(nproc)
sudo make install
sudo ldconfig
popd # build
popd # zlib-ng
rm -rf zlib-ng

# Build 7-Zip
git clone https://github.com/HeXis-YS/7-Zip
pushd 7-Zip
git checkout linux
pushd CPP/7zip/Bundles/Alone7z
wget https://github.com/nidud/asmc/raw/refs/heads/master/bin/asmc64
sudo install -m755 asmc64 /usr/local/bin/asmc
make -j$(nproc) -f ../../cmpl_clang_x64.mak
sudo install -m755 b/c_x64/7zr /usr/local/bin/7zr
popd
popd
rm -rf 7-Zip

# Build ECT
sudo apt install -y nasm
git clone https://github.com/fhanau/Efficient-Compression-Tool ect
pushd ect # /tmp/ect
git checkout $(git describe --abbrev=0 --tags)
git submodule update --init --recursive
sed -i -e 's/size < 1200000000/1/g' src/main.cpp
mkdir build
pushd build # /tmp/ect/build
cmake ../src \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_AR=$(which gcc-ar) \
    -DCMAKE_RANLIB=$(which gcc-ranlib) \
    -DCMAKE_C_FLAGS_RELEASE="$GCC_CFLAGS" \
    -DCMAKE_CXX_FLAGS_RELEASE="$GCC_CFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$GCC_LDFLAGS"
make -j$(nproc)
sudo install -m755 ect /usr/local/bin/ect
popd # /tmp/ect
popd # /tmp
rm -rf ect

git clone https://github.com/ebiggers/libdeflate
pushd libdeflate
mkdir build
pushd build
cmake .. \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_AR=$(which gcc-ar) \
    -DCMAKE_RANLIB=$(which gcc-ranlib) \
    -DCMAKE_C_FLAGS_RELEASE="$GCC_CFLAGS" \
    -DCMAKE_EXE_LINKER_FLAGS="$GCC_LDFLAGS" \
    -DLIBDEFLATE_BUILD_SHARED_LIB=OFF
make -j$(nproc)
sudo install -m755 programs/libdeflate-gzip /usr/local/bin/libdeflate-gzip
popd
popd
rm -rf libdeflate

popd

# Fix color terminal
sed -i -e 's/xterm-color/xterm|xterm-color/' ~/.bashrc

# Merge .bash_profile into .profile
cat ~/.bash_profile >> ~/.profile
rm ~/.bash_profile

# TMUX 24-bit color support
echo 'set -sg terminal-overrides ",*:RGB"' >> ~/.tmux.conf
echo 'set -ag terminal-overrides ",$TERM:RGB"' >> ~/.tmux.conf
