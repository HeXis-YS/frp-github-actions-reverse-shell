#!/bin/bash
# Warn when workflow is about to close
(sleep 300m && wall "Warning: The workflow will be closed within 1 Hour.") &
(sleep 330m && wall "Warning: The workflow will be closed within 30 Minutes.") &
(sleep 350m && wall "Warning: The workflow will be closed within 10 Minutes.") &

# Enable bbr by default
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr

# Mount /tmp as tmpfs
sudo mount -t tmpfs -o rw,nosuid,noatime,nodev,size=10G tmpfs /tmp

# Tuning ext4 mount options
sudo mount -o remount,noatime,nobarrier,nodiscard,commit=21600 /mnt
sudo mount -o remount,noatime,nobarrier,nodiscard,commit=21600 /

# Make the whole /mnt as swap
if [[ ${INIT_MKSWAP} == 'true' ]]; then
    sudo swapoff -a
    sudo rm -rf /mnt/*
    sudo fallocate -l $(df --output=avail -B 1 . | tail -n 1) /mnt/swapfile
    sudo chmod 600 /mnt/swapfile
    sudo mkswap /mnt/swapfile
    sudo swapon /mnt/swapfile
fi

# Remove unnecessary files
if [[ ${INIT_CLEAN_SPACE} == 'true' ]]; then
    sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /usr/local/share/boost "$AGENT_TOOLSDIRECTORY" /opt/hostedtoolcache/CodeQL &
    sudo docker image prune --all --force &
fi

# Replace port number for multiple instance
sed -i "s/@PORT_NUMBER@/${INIT_PORT_NUMBER}/g" frpc.ini

# Auto load .profile
echo '. "$HOME/.profile"' >> "$HOME/.bash_profile"

# OpenSSH cipher and kex
sudo bash -c 'echo "Ciphers aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com" >> /etc/ssh/sshd_config.d/60-custom.conf'
sudo bash -c 'echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,sntrup761x25519-sha512@openssh.com" >> /etc/ssh/sshd_config.d/60-custom.conf'
sudo systemctl restart sshd

