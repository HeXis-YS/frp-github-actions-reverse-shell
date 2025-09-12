#!/usr/bin/bash

sudo install -D etc/buildflags /usr/local/etc/action-shell/.buildflags
sudo install -m755 bin/* /usr/local/bin/

source /usr/local/etc/action-shell/.buildflags

pushd /tmp

# Build zlib-ng
git clone -b stable --depth 1 --single-branch --no-tags https://github.com/zlib-ng/zlib-ng
mkdir zlib-ng/build
pushd zlib-ng/build
cmake .. \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_C_FLAGS_RELEASE="$CLANG_CFLAGS" \
    -DCMAKE_SHARED_LINKER_FLAGS="$CLANG_LDFLAGS" \
    -DZLIB_COMPAT=ON \
    -DZLIB_ENABLE_TESTS=OFF \
    -DWITH_NATIVE_INSTRUCTIONS=ON \
    -DNATIVE_ARCH_OVERRIDE="$ARCH_CFLAGS" \
    -DWITH_RUNTIME_CPU_DETECTION=OFF \
    -DWITH_GTEST=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DWITH_SANITIZER=OFF
make -j$(nproc)
sudo make install
sudo ldconfig
popd # zlib-ng/build
rm -rf zlib-ng

popd # /tmp

# Fix color terminal
sed -i 's/xterm-color/xterm|xterm-color/' ~/.bashrc

# Merge .bash_profile into .profile
cat ~/.bash_profile >> ~/.profile
rm ~/.bash_profile

# TMUX 24-bit color support
echo 'set -sg terminal-overrides ",*:RGB"' >> ~/.tmux.conf
echo 'set -ag terminal-overrides ",$TERM:RGB"' >> ~/.tmux.conf
