#!/bin/bash -x

# Set up console output
sed -i '/GRUB_CMDLINE_LINUX/s/"$/console=tty0 console=ttyS0,115200"/' /etc/default/grub
sed -i 's/GRUB_HIDDEN_TIMEOUT_QUIET=true/GRUB_HIDDEN_TIMEOUT_QUIET=false/' /etc/default/grub
sed -i 's/quiet\s*//' /etc/default/grub
echo 'GRUB_TERMINAL="console serial"' >>/etc/default/grub
echo 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --stop=1"' >> /etc/default/grub

# Reconfigure grub
update-grub

# I do *not* like tmp being reaped on reboot
sed -i '/tmp/s/-\s*$/60d/' /usr/lib/tmpfiles.d/tmp.conf

# Set up static networking
cat >/etc/netplan/01-netcfg.yaml <<EOF
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    en:
      match:
        name: 'enp*s0'
      addresses:
        - 192.168.123.138/24
      gateway4: 192.168.123.254
      nameservers:
        search: [digitalkingdom.org]
        addresses: [192.168.123.254, 8.8.8.8]
EOF
netplan apply

# User setup, so we can ssh in
/bin/echo -e 'test123\ntest123' | adduser --gecos 'Robin Powell' rlpowell
echo 'rlpowell    ALL=(ALL)    TYPE=unconfined_t ROLE=unconfined_r   ALL' >/etc/sudoers.d/rlpowell
apt-get install -y zsh vim

# Please don't ask stupid questions
echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections

# Make sure ssh is awake
dpkg-reconfigure openssh-server

# Install docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
apt-get update
# The versions are because of https://alerts.home-assistant.io/#docker_2010.markdown
apt-get install -y docker-ce=5:19.03.14~3-0~ubuntu-bionic docker-ce-cli=5:19.03.14~3-0~ubuntu-bionic containerd.io=1.3.9-1
systemctl enable docker

echo 'loop
virtio
9p
9pnet
9pnet_virtio' >> /etc/modules

# Set up the hassio mount point
mkdir -p /usr/share/hassio
echo 'hassio /usr/share/hassio 9p trans=virtio,version=9p2000.L 0 0' >>/etc/fstab

# Set up the influxdb mount point
apt-get install -y influxdb influxdb-client
echo 'influxdb /var/lib/influxdb 9p trans=virtio,version=9p2000.L 0 0' >>/etc/fstab

# Pepare to install hassio
apt-get install -y jq avahi-daemon dbus network-manager

# Get the hassio cli
wget https://github.com/home-assistant/cli/releases/latest/download/ha_amd64 -O /usr/local/bin/ha_amd64
chmod 755 /usr/local/bin/ha_amd64
cat >/usr/local/bin/ha <<'EOF'
#!/bin/bash

/usr/local/bin/ha_amd64 --api-token="$(cat /usr/share/hassio/homeassistant.json | jq -r ."access_token")" --endpoint "$(grep supervisor /usr/share/hassio/dns/hosts | awk '{ print $1 }')" "$@"
EOF
chmod 755 /usr/local/bin/ha

curl -sL https://raw.githubusercontent.com/home-assistant/supervised-installer/master/installer.sh | bash -s && ha su repair && ha host reboot
