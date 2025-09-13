# Fix KVM permissions
groupadd -r kvm -g $1 || groupmod -g $1 kvm
gpasswd -a rhino kvm || true

# Disable man-db processing
dpkg-divert --divert /usr/bin/mandb.real --rename /usr/bin/mandb
echo -e '#!/bin/sh\nexit 0' > /usr/bin/mandb
chmod 755 /usr/bin/mandb

# Install dependencies
apt update
apt upgrade -y
apt autopurge -y
apt install -y libeatmydata1 udev
rm -rf /var/lib/apt/lists/*

# Configure libs
echo /usr/local/lib > /etc/ld.so.conf.d/00custom.conf
echo /lib/$(uname -m)-linux-gnu/libeatmydata.so > /etc/ld.so.preload
ldconfig

# Fix color terminal
sed -i 's/#force_color_prompt/force_color_prompt/' /home/rhino/.bashrc

# Self deletion
rm -f $(realpath $0)
