# Disable man-db processing
dpkg-divert --divert /usr/bin/mandb.real --rename /usr/bin/mandb
echo -e '#!/bin/sh\nexit 0' > /usr/bin/mandb
chmod 755 /usr/bin/mandb

apt update

# Configure libs
apt install -y libeatmydata1
echo /usr/local/lib > /etc/ld.so.conf.d/00custom.conf
echo /lib/$(uname -m)-linux-gnu/libeatmydata.so > /etc/ld.so.preload
ldconfig

# Add user
apt install -y adduser sudo
addgroup --gid $2 debian
adduser --uid $1 --gid $2 --disabled-password --gecos "" debian
usermod -aG sudo debian
echo "debian ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Fix KVM permissions
addgroup --gid $3 kvm || groupmod -g $3 kvm
gpasswd -a debian kvm || true

# Install dependencies
apt install -y udev nano readline-common

# Fix color terminal
sed -i 's/#force_color_prompt/force_color_prompt/' /home/debian/.bashrc

# Self deletion
rm -f $(realpath $0)
