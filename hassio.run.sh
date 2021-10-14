#!/bin/bash -x

# Sources (for some of this):
# - https://community.home-assistant.io/t/installing-home-assistant-supervised-on-debian-11/200253
# - https://github.com/home-assistant/supervised-installer
# - https://www.home-assistant.io/installation/linux#install-home-assistant-supervised

cat /etc/network/interfaces

# Very basic networking
cat <<'EOF' >/etc/network/interfaces
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback
EOF
cat <<'EOF' >/etc/network/interfaces.d/enp3s0
auto enp3s0
iface enp3s0 inet static
    address 192.168.123.138
    network 192.168.123.0
    netmask 255.255.255.0
    broadcast 192.168.123.255
    gateway 192.168.123.254
EOF
cat <<'EOF' >/etc/resolv.conf
search digitalkingdom.org
nameserver 192.168.123.254 8.8.8.8
EOF

ifup enp3s0

# Time fix
timedatectl set-timezone America/Los_Angeles

# Update everything
rm -rf /var/lib/apt/lists/*
apt-get update && apt-get upgrade -y && apt-get autoremove -y

# I do *not* like tmp being reaped on reboot
sed -i '/tmp/s/-\s*$/60d/' /usr/lib/tmpfiles.d/tmp.conf

# Basics, networking, etc
apt-get install -y zsh vim openssh-server network-manager curl sudo

# User setup, so we can ssh in
/bin/echo -e 'test123\ntest123' | adduser --gecos 'Robin Powell' rlpowell
echo 'rlpowell    ALL=(ALL)    TYPE=unconfined_t ROLE=unconfined_r   ALL' >/etc/sudoers.d/rlpowell
mkdir -p /home/rlpowell/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA2yFDfoKcwBxG830sz9MelsMLoGHd7Y2wBG7M6d9hzl4FYDiLbw9qZ07QOuYe1UX3GStLeyklK51OnO7D8PwOehJH8fwWQc+lDLWm0znplX1bbOIjA2iPBcNDwDWA3A9cC3/30jz3EmIgpR7PC0JMuVLb7XOi7CwQwbnOrqG5MQM= rlpowell@chain' >/home/rlpowell/.ssh/authorized_keys

# Please don't ask stupid questions
echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

# Get mail working, for cron
DEBIAN_FRONTEND=noninteractive apt-get -y install nullmailer
echo 'rlpowell@digitalkingdom.org' >/etc/nullmailer/adminaddr
echo 'hassio.digitalkingdom.org' >/etc/nullmailer/defaultdomain
echo 'mail.digitalkingdom.org' >/etc/nullmailer/remotes
systemctl start nullmailer
systemctl enable nullmailer

# Get cron backups working
mkdir -p /var/lib/influxdb/backups
cat >/usr/local/bin/influxdb_backup <<'EOF'
#!/bin/bash

influxd backup /var/lib/influxdb/backups/influxdb-backup-week-$(date +%V)
influxd backup -database waffles_sensors /var/lib/influxdb/backups/influxdb-backup-week-$(date +%V)
tar -zcf /var/lib/influxdb/backups/influxdb-backup-week-$(date +%V).tgz /var/lib/influxdb/backups/influxdb-backup-week-$(date +%V)/
rm -rf /var/lib/influxdb/backups/influxdb-backup-week-$(date +%V)/
EOF
chmod 755 /usr/local/bin/influxdb_backup

cat >/usr/local/bin/influxdb_restore_latest <<'EOF'
#!/bin/bash

mkdir /tmp/infuxdb-restore/ ; ls -rt /var/lib/influxdb/backups/* | tail -n 1 | sudo xargs tar -C /tmp/infuxdb-restore/ -xvf

sudo influxd restore -metadir /var/lib/influxdb/meta/ /tmp/infuxdb-restore/var/lib/influxdb/backups/*/
sudo influxd restore -metadir /var/lib/influxdb/meta/ -datadir /var/lib/influxdb/data/ -database waffles_sensors /tmp/infuxdb-restore/var/lib/influxdb/backups/*/
sudo chown -R influxdb:influxdb /var/lib/influxdb/
sudo systemctl restart influxdb
sleep 5
echo 'show databases' | sudo influx
EOF
chmod 755 /usr/local/bin/influxdb_restore_latest

cat >crontab <<'EOF'
MAILTO=rlpowell@digitalkingdom.org
LANG=en_US.UTF-8
13 13 * * * ha backups new
14 14 * * * /usr/local/bin/influxdb_backup
EOF

crontab crontab

# Make sure ssh is awake
dpkg-reconfigure openssh-server

# Install docker
curl -fsSL get.docker.com | sh

# Prep for libvirt shared directory mount points
echo 'loop
virtio
9p
9pnet
9pnet_virtio' >> /etc/modules

# Set up the hassio mount point
mkdir -p /usr/share/hassio/backup
echo 'hassio-backups /usr/share/hassio/backup 9p trans=virtio,version=9p2000.L 0 0' >>/etc/fstab

# Set up the influxdb mount point
apt-get install -y influxdb influxdb-client
echo 'influxdb-backups /var/lib/influxdb/backups 9p trans=virtio,version=9p2000.L 0 0' >>/etc/fstab

# Pepare to install hassio
apt --fix-broken install
apt-get install -y software-properties-common apparmor-utils apt-transport-https ca-certificates curl dbus jq udisks2 wget

systemctl disable ModemManager

systemctl stop ModemManager

cd /usr/local/src
curl -Lo installer.sh https://raw.githubusercontent.com/home-assistant/supervised-installer/master/installer.sh

wget https://github.com/home-assistant/os-agent/releases/download/1.2.2/os-agent_1.2.2_linux_x86_64.deb

echo
echo
echo -e 'OK, quit the console now with ctrl-]'
echo
echo
