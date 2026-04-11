#!/usr/bin/bash

# Fix color terminal
sed -i 's/xterm-color/xterm|xterm-color/' ~/.bashrc

# Merge .bash_profile into .profile
cat ~/.bash_profile >> ~/.profile
rm ~/.bash_profile

# TMUX 24-bit color support
echo 'set -sg terminal-overrides ",*:RGB"' >> ~/.tmux.conf
echo 'set -ag terminal-overrides ",$TERM:RGB"' >> ~/.tmux.conf
