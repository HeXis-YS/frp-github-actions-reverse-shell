#!/bin/bash
(sleep 300m && wall "Warning: The workflow will be closed within 1 Hour.") &
(sleep 330m && wall "Warning: The workflow will be closed within 30 Minutes.") &
(sleep 350m && wall "Warning: The workflow will be closed within 10 Minutes.") &

MNT_DEVICE=$(mount | grep /mnt | awk '{print $1}')
sudo swapoff -a
sudo umount /mnt
sudo mkswap $MNT_DEVICE
sudo swapon $MNT_DEVICE
