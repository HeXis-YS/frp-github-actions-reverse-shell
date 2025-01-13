#!/bin/bash
# Warn when workflow is about to close
# (sleep 300m && wall "Warning: The workflow will be closed within 1 Hour.") &
# (sleep 330m && wall "Warning: The workflow will be closed within 30 Minutes.") &
# (sleep 350m && wall "Warning: The workflow will be closed within 10 Minutes.") &

# Disable swap
swapoff -a
rm -f /mnt/swapfile

# Disk tweaks
echo -n 0 > /sys/class/block/sda/queue/add_random
echo -n 0 > /sys/class/block/sda/queue/iostats
echo -n 0 > /sys/class/block/sda/queue/rotational
echo -n none > /sys/class/block/sda/queue/scheduler
echo -n 2 > /sys/class/block/sda/queue/rq_affinity
echo -n 0 > /sys/class/block/sdb/queue/add_random
echo -n 0 > /sys/class/block/sdb/queue/iostats
echo -n 0 > /sys/class/block/sdb/queue/rotational
echo -n none > /sys/class/block/sdb/queue/scheduler
echo -n 2 > /sys/class/block/sdb/queue/rq_affinity

# Tuning ext4 mount options for /
tune2fs -O fast_commit $(findmnt -n -o SOURCE /)
mount -o remount,nodev,noatime,nodiratime,lazytime,nobarrier,nodiscard,commit=21600 /

# Tuning ext4 mount options for /mnt
source /etc/os-release
if [ "$VERSION_ID" == "24.04" ]; then
    umount /mnt
    tune2fs -O "^has_journal" /dev/disk/cloud/azure_resource-part1
    e2fsck -y -f /dev/disk/cloud/azure_resource-part1
    mount -o defaults,nodev,noatime,nodiratime,lazytime /mnt
else
    mount -o remount,nodev,noatime,nodiratime,lazytime,nobarrier,nodiscard,commit=21600 /mnt
fi

# Mount /tmp as tmpfs
mount -t tmpfs -o rw,nodev,noatime,nodiratime,lazytime,size=$(awk '/MemTotal/{print $2}' /proc/meminfo)K tmpfs /tmp

# /mnt permission
chown runner:docker /mnt

# Enable bbr by default
sysctl -w \
    net.ipv4.tcp_congestion_control=bbr \
    net.core.default_qdisc=fq_codel \
    net.ipv4.tcp_ecn=1 \
    net.ipv6.conf.all.disable_ipv6=1 \
    net.ipv6.conf.default.disable_ipv6=1 \
    net.ipv6.conf.lo.disable_ipv6=1 \
    net.ipv4.ip_forward=0 \
    net.ipv4.conf.default.forwarding=0 \
    net.ipv4.conf.all.forwarding=0 \
    net.core.netdev_max_backlog=16384 \
    net.core.somaxconn=8192 \
    net.core.rmem_max=16777216 \
    net.core.wmem_max=4194304 \
    net.ipv4.tcp_rmem="4096 131072 16777216" \
    net.ipv4.tcp_wmem="4096 131072 4194304" \
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
    vm.vfs_cache_pressure=50 \
    kernel.core_pattern="|/usr/bin/false" \
    kernel.randomize_va_space=0

# Configure ZRAM
apt update
apt install -y linux-modules-extra-$(uname -r) earlyoom
systemctl start earlyoom
modprobe zram
echo -n zstd > /sys/block/zram0/comp_algorithm
echo -n $(($(awk '/MemTotal/{print $2}' /proc/meminfo) * 5))K > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon -p 0 /dev/zram0
sysctl -w  \
    vm.swappiness=200 \
    vm.watermark_boost_factor=0 \
    vm.watermark_scale_factor=125 \
    vm.page-cluster=0

# Fix color terminal
sed -i -e 's/xterm-color/xterm|xterm-color/' /home/runner/.bashrc

# Merge .bash_profile into .profile
cat /home/runner/.bash_profile >> /home/runner/.profile
rm /home/runner/.bash_profile

# TMUX 24-bit color support
echo 'set -sg terminal-overrides ",*:RGB"' >> /home/runner/.tmux.conf
echo 'set -ag terminal-overrides ",$TERM:RGB"' >> /home/runner/.tmux.conf

# OpenSSH cipher and kex
# bash -c 'echo "Ciphers aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com" >> /etc/ssh/sshd_config.d/60-custom.conf'
# bash -c 'echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,sntrup761x25519-sha512@openssh.com" >> /etc/ssh/sshd_config.d/60-custom.conf'
# systemctl restart sshd
