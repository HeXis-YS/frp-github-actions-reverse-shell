#!/bin/bash
MNT_DEVICE=$(mount | grep /mnt | awk '{print $1}')
sudo swapoff -a
sudo umount /mnt
sudo mkswap $MNT_DEVICE
sudo swapon $MNT_DEVICE
