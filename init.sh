#!/bin/bash
# Warn when workflow is about to close
(sleep 300m && wall "Warning: The workflow will be closed within 1 Hour.") &
(sleep 330m && wall "Warning: The workflow will be closed within 30 Minutes.") &
(sleep 350m && wall "Warning: The workflow will be closed within 10 Minutes.") &

# Enable bbr by default
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr

# Mount /tmp as tmpfs
sudo mount -t tmpfs -o rw,nosuid,noatime,nodev,size=10G tmpfs /tmp
