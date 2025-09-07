#!/usr/bin/bash
# This script should be run as root

# Configure libs
echo /lib/x86_64-linux-gnu/libeatmydata.so > /etc/ld.so.preload
ldconfig

# Useful programs
install -m 755 bin/* /usr/local/bin/

# Disk tweaks
echo -n 0 | tee \
    /sys/class/block/sd[a-z]/queue/add_random \
    /sys/class/block/sd[a-z]/queue/iostats \
    /sys/class/block/sd[a-z]/queue/rotational
echo -n none | tee \
    /sys/class/block/sd[a-z]/queue/scheduler
echo -n 2 | tee \
    /sys/class/block/sd[a-z]/queue/rq_affinity

# Disable swap
swapoff -a
rm -f /mnt/swapfile

# ext4 mount options for /
tune2fs -O fast_commit $(findmnt -n -o SOURCE /)
mount -o remount,nodiscard,nodev,noatime,lazytime,nobarrier,noauto_da_alloc,commit=21600,inode_readahead_blks=4096 /

# ext4 mount options for /mnt
source /etc/os-release
if [ "$VERSION_ID" == "24.04" ]; then
    umount /mnt
    modprobe brd rd_size=65536 max_part=1
    mke2fs -F -O journal_dev /dev/ram0
    mke2fs -F -O ^resize_inode,has_journal,sparse_super2,fast_commit,orphan_file,extent,flex_bg,inline_data -E num_backup_sb=0 -J device=/dev/ram0 -m 0 /dev/disk/cloud/azure_resource-part1
    mount -o nodev,noatime,lazytime,nobarrier,noauto_da_alloc,commit=21600,data=writeback,inode_readahead_blks=4096 /dev/disk/cloud/azure_resource-part1 /mnt
    # sudo mkfs.btrfs -f -O block-group-tree /dev/disk/cloud/azure_resource-part1
    # mount -o nodev,noatime,lazytime,nobarrier,commit=21600,compress-force=zstd:15,nodiscard,ssd /dev/disk/cloud/azure_resource-part1 /mnt
else
    tune2fs -O fast_commit /dev/disk/cloud/azure_resource-part1
    mount -o remount,nodev,noatime,lazytime,nobarrier,noauto_da_alloc,commit=21600,inode_readahead_blks=4096 /mnt
fi

# /mnt permission
chown runner:docker /mnt

# Mount /tmp as tmpfs
mount -t tmpfs -o rw,nodev,noatime,nodiratime,lazytime,size=$(awk '/MemTotal/{print $2}' /proc/meminfo)K tmpfs /tmp

# Sysctl
sysctl -w \
    net.ipv4.tcp_congestion_control=bbr \
    net.core.default_qdisc=fq \
    net.ipv4.tcp_ecn=1 \
    net.ipv6.conf.all.disable_ipv6=1 \
    net.ipv6.conf.default.disable_ipv6=1 \
    net.ipv6.conf.lo.disable_ipv6=1 \
    net.ipv4.ip_forward=0 \
    net.ipv4.conf.default.forwarding=0 \
    net.ipv4.conf.all.forwarding=0 \
    net.core.netdev_max_backlog=16384 \
    net.core.somaxconn=8192 \
    net.core.rmem_max=67108864 \
    net.core.wmem_max=67108864 \
    net.ipv4.tcp_rmem="4096 131072 67108864" \
    net.ipv4.tcp_wmem="4096 131072 67108864" \
    net.ipv4.udp_rmem_min=8192 \
    net.ipv4.udp_wmem_min=8192 \
    net.ipv4.tcp_fastopen=3 \
    net.ipv4.tcp_max_syn_backlog=8192 \
    net.ipv4.tcp_max_tw_buckets=2097152 \
    net.ipv4.tcp_tw_reuse=1 \
    net.ipv4.tcp_fin_timeout=10 \
    net.ipv4.tcp_slow_start_after_idle=0 \
    net.ipv4.tcp_no_metrics_save=1 \
    net.ipv4.tcp_keepalive_time=60 \
    net.ipv4.tcp_keepalive_intvl=10 \
    net.ipv4.tcp_keepalive_probes=6 \
    net.ipv4.conf.default.rp_filter=1 \
    net.ipv4.conf.all.rp_filter=1 \
    net.ipv4.tcp_synack_retries=1 \
    net.ipv4.tcp_syn_retries=1 \
    net.ipv4.conf.all.accept_redirects=0 \
    net.ipv4.conf.default.accept_redirects=0 \
    net.ipv4.conf.all.send_redirects=0 \
    net.ipv4.conf.default.send_redirects=0 \
    net.ipv4.conf.all.secure_redirects=0 \
    net.ipv4.conf.default.secure_redirects=0 \
    net.ipv6.conf.all.accept_redirects=0 \
    net.ipv6.conf.default.accept_redirects=0 \
    net.ipv4.icmp_echo_ignore_all=1 \
    net.ipv6.icmp.echo_ignore_all=1 \
    vm.dirty_ratio=50 \
    vm.dirty_background_ratio=5 \
    vm.vfs_cache_pressure=50 \
    kernel.core_pattern="|/usr/bin/false" \
    kernel.randomize_va_space=0

# Replace qdisc manually
tc qdisc replace dev eth0 root fq

# Disable man-db processing
dpkg-divert --divert /usr/bin/mandb.real --rename /usr/bin/mandb
echo -e '#!/bin/sh\nexit 0' > /usr/bin/mandb
chmod 755 /usr/bin/mandb

# ZRAM
apt update
apt install -y linux-modules-extra-$(uname -r) earlyoom
systemctl start earlyoom
modprobe zram
echo -n zstd > /sys/block/zram0/comp_algorithm
echo -n $(($(awk '/MemTotal/{print $2}' /proc/meminfo) * 2))K > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon -p 0 /dev/zram0
sysctl -w  \
    vm.swappiness=200 \
    vm.watermark_boost_factor=0 \
    vm.watermark_scale_factor=125 \
    vm.page-cluster=0

# OpenSSH cipher and kex
# bash -c 'echo "Ciphers aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com" >> /etc/ssh/sshd_config.d/60-custom.conf'
# bash -c 'echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,sntrup761x25519-sha512@openssh.com" >> /etc/ssh/sshd_config.d/60-custom.conf'

# Fix password login
sed -i -e '/^PasswordAuthentication/s/^/# /' -e '/^KbdInteractiveAuthentication/s/^/# /' \
    /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "KbdInteractiveAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart ssh.socket

# Docker
mkdir -p /etc/docker
echo '{"data-root": "/mnt/docker"}' > /etc/docker/daemon.json
systemctl restart docker

# Add runner to kvm group
groupadd -r kvm
gpasswd -a runner kvm

# Move $HOME to /mnt
mv /home/runner /mnt/runner
ln -sf /mnt/runner /home/runner
chown -h runner:docker /home/runner

# Synchronize caches
sync
sysctl -w vm.drop_caches=3

# Trim disk
# fstrim -v /mnt
# fstrim -v /boot
# fstrim -v /
