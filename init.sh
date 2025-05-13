#!/usr/bin/bash

# Build zlib-ng
git clone https://github.com/zlib-ng/zlib-ng
pushd zlib-ng
git checkout $(git describe --abbrev=0 --tags)
mkdir build
pushd build
cmake .. \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_C_FLAGS_RELEASE="-Wno-unused-command-line-argument -Ofast -flto=full -fuse-ld=lld" \
    -DZLIB_COMPAT=ON -DZLIB_ENABLE_TESTS=OFF \
    -DWITH_NATIVE_INSTRUCTIONS=ON \
    -DWITH_RUNTIME_CPU_DETECTION=OFF \
    -DWITH_GTEST=OFF \
    -DBUILD_SHARED_LIBS=ON
make -j$(nproc)
sudo make install
popd
popd
# sudo ldconfig

# Fix color terminal
sed -i -e 's/xterm-color/xterm|xterm-color/' ~/.bashrc

# Merge .bash_profile into .profile
cat ~/.bash_profile >> ~/.profile
rm ~/.bash_profile

# TMUX 24-bit color support
echo 'set -sg terminal-overrides ",*:RGB"' >> ~/.tmux.conf
echo 'set -ag terminal-overrides ",$TERM:RGB"' >> ~/.tmux.conf
