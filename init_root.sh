#!/usr/bin/bash
# This script should be run as root

# Configure libs
echo /usr/local/lib > /etc/ld.so.conf.d/00_custom.conf
echo /lib/$(uname -m)-linux-gnu/libeatmydata.so > /etc/ld.so.preload
ldconfig

# Useful programs
install -m 755 bin/* /usr/local/bin/

# Disk tweaks
pushd /sys/class/block
echo none | tee \
    sd[a-z]/queue/scheduler
echo 0 | tee \
    sd[a-z]/queue/add_random \
    sd[a-z]/queue/iostats \
    sd[a-z]/queue/rotational
echo 2 | tee \
    sd[a-z]/queue/rq_affinity
# echo 4096 | tee \
#     sd[a-z]/queue/nr_requests
echo 1024 | tee \
    sd[a-z]/queue/read_ahead_kb
popd

# ext4 mount options for /
tune2fs -O fast_commit $(findmnt -n -o SOURCE /)
mount -o remount,nodiscard,nodev,noatime,lazytime,nobarrier,noauto_da_alloc,commit=21600,inode_readahead_blks=4096 /

# Disable swap
swapoff -a
rm -f /mnt/swapfile

TMP_DEVICE=$(findmnt -n -o SOURCE /mnt) 
if [ $TMP_DEVICE ]; then
    # ext4 mount options for /mnt
    source /etc/os-release
    if [ "$VERSION_ID" == "24.04" ]; then
        umount /mnt
        modprobe brd rd_size=65536 max_part=1
        mke2fs -F -O journal_dev /dev/ram0
        mke2fs -F -O ^resize_inode,has_journal,sparse_super2,fast_commit,orphan_file,extent,flex_bg,inline_data -E num_backup_sb=0 -J device=/dev/ram0 -m 0 $TMP_DEVICE
        mount -o nodev,noatime,lazytime,nobarrier,noauto_da_alloc,commit=21600,data=writeback,inode_readahead_blks=4096 $TMP_DEVICE /mnt
        # sudo mkfs.btrfs -f -O block-group-tree $TMP_DEVICE
        # mount -o nodev,noatime,lazytime,nobarrier,commit=21600,compress-force=zstd:15,nodiscard,ssd $TMP_DEVICE /mnt
    else
        tune2fs -O fast_commit $TMP_DEVICE
        mount -o remount,nodev,noatime,lazytime,nobarrier,noauto_da_alloc,commit=21600,inode_readahead_blks=4096 /mnt
    fi

    # /mnt permission
    chown runner:docker /mnt

    # Make OverlayFS on /mnt
    mkdir -p /mnt/.overlay
    pushd /mnt/.overlay
    mkdir -p work_dir upper_dir merged_dir
    mount -t overlay overlay -o lowerdir=/,upperdir=upper_dir,workdir=work_dir merged_dir
    pushd merged_dir
    mounts=$(awk '{print $2}' /proc/mounts)
    for mp in $mounts; do
        if [ "$mp" == "/" ] || [ "$mp" == "/mnt"* ]; then
            continue
        fi
        mount --rbind $mp .$mp
        mount --make-rslave .$mp
    done
    popd
    popd
fi

# Mount /tmp as tmpfs
mount -t tmpfs -o rw,nodev,noatime,nodiratime,lazytime,size=$(awk '/MemTotal/{print $2}' /proc/meminfo)K tmpfs /tmp

# Sysctl
sysctl -w \
    kernel.core_pattern="|/usr/bin/false" \
    kernel.randomize_va_space=0 \
    kernel.sched_autogroup_enabled=0 \
    kernel.unprivileged_bpf_disabled=1 \
    net.core.default_qdisc=fq \
    net.core.netdev_max_backlog=16384 \
    net.core.rmem_max=67108864 \
    net.core.somaxconn=8192 \
    net.core.wmem_max=16777216 \
    net.ipv4.conf.all.accept_redirects=0 \
    net.ipv4.conf.all.forwarding=0 \
    net.ipv4.conf.all.rp_filter=1 \
    net.ipv4.conf.all.secure_redirects=0 \
    net.ipv4.conf.all.send_redirects=0 \
    net.ipv4.conf.default.accept_redirects=0 \
    net.ipv4.conf.default.forwarding=0 \
    net.ipv4.conf.default.rp_filter=1 \
    net.ipv4.conf.default.secure_redirects=0 \
    net.ipv4.conf.default.send_redirects=0 \
    net.ipv4.icmp_echo_ignore_all=1 \
    net.ipv4.ip_forward=0 \
    net.ipv4.tcp_congestion_control=bbr \
    net.ipv4.tcp_ecn=1 \
    net.ipv4.tcp_fastopen=3 \
    net.ipv4.tcp_fin_timeout=10 \
    net.ipv4.tcp_keepalive_intvl=10 \
    net.ipv4.tcp_keepalive_probes=6 \
    net.ipv4.tcp_keepalive_time=60 \
    net.ipv4.tcp_max_syn_backlog=8192 \
    net.ipv4.tcp_max_tw_buckets=2097152 \
    net.ipv4.tcp_no_metrics_save=1 \
    net.ipv4.tcp_rmem="4096 131072 67108864" \
    net.ipv4.tcp_slow_start_after_idle=0 \
    net.ipv4.tcp_syn_retries=1 \
    net.ipv4.tcp_synack_retries=1 \
    net.ipv4.tcp_tw_reuse=1 \
    net.ipv4.tcp_wmem="4096 131072 16777216" \
    net.ipv4.udp_rmem_min=8192 \
    net.ipv4.udp_wmem_min=8192 \
    net.ipv6.conf.all.accept_redirects=0 \
    net.ipv6.conf.all.secure_redirects=0 \
    net.ipv6.conf.default.accept_redirects=0 \
    net.ipv6.conf.default.secure_redirects=0 \
    net.ipv6.icmp.echo_ignore_all=1 \
    vm.dirty_background_ratio=5 \
    vm.dirty_ratio=50 \
    vm.dirty_writeback_centisecs=1500 \
    vm.extfrag_threshold=100 \
    vm.mmap_min_addr=65536 \
    vm.vfs_cache_pressure=50

echo 30000 > /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
echo 0 > /sys/devices/virtual/graphics/fbcon/cursor_blink
echo 0 > /sys/kernel/rcu_expedited
echo 4000 > /sys/kernel/mm/ksm/sleep_millisecs
echo 1000 > /sys/kernel/mm/ksm/pages_to_scan

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
echo zstd > /sys/block/zram0/comp_algorithm
echo $(($(awk '/MemTotal/{print $2}' /proc/meminfo) * 2))K > /sys/block/zram0/disksize
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
sed -i /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* \
    -e '/^PasswordAuthentication/s/^/# /' \
    -e '/^KbdInteractiveAuthentication/s/^/# /'
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "KbdInteractiveAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart ssh.socket

# Add runner to kvm group
groupadd -r kvm
gpasswd -a runner kvm

# Fix arm default shell
chsh -s /usr/local/bin/overlay-root runner

# Synchronize caches
sync
sysctl -w vm.drop_caches=3

# Trim disk
# fstrim -v /mnt
# fstrim -v /boot
# fstrim -v /
