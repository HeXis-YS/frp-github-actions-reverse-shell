#!/bin/bash
sudo swapoff -a
sudo rm -rf /mnt/*
sudo fallocate -l $(df --output=avail -B 1 . | tail -n 1) /mnt/swapfile
sudo chmod 600 /mnt/swapfile
sudo mkswap /mnt/swapfile
sudo swapon /mnt/swapfile
