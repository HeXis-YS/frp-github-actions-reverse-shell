#!/bin/bash
# Warn when workflow is about to close
(sleep 300m && wall "Warning: The workflow will be closed within 1 Hour.") &
(sleep 330m && wall "Warning: The workflow will be closed within 30 Minutes.") &
(sleep 350m && wall "Warning: The workflow will be closed within 10 Minutes.") &

# Enable bbr by default
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr

# Mount /tmp as tmpfs
sudo mount -t tmpfs -o rw,nosuid,noatime,nodev,size=10G tmpfs /tmp

# Make the whole /mnt as swap
if [[ ${INIT_MKSWAP} == 'true' ]]; then
    sudo swapoff -a
    sudo rm -rf /mnt/*
    sudo fallocate -l $(df --output=avail -B 1 . | tail -n 1) /mnt/swapfile
    sudo chmod 600 /mnt/swapfile
    sudo mkswap /mnt/swapfile
    sudo swapon /mnt/swapfile
fi