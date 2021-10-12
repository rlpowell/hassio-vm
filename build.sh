# run with "sudo bash -x" or similar

# echo "If you're reading this you should re-do this to conform with https://community.home-assistant.io/t/installing-home-assistant-supervised-on-debian-10/200253 ; also maybe read README-INSTALL-METHODS.txt"
# exit

cat <<'EOF'

NOW IS A GOOD TIME TO STOP AND FORCE BACKUPS IF YOU HAVEN'T YET.  See root's crontab on hassio.

Hit enter to continue.

EOF

read line


setenforce 0

virsh shutdown hassio$TESTVERSION

sleep 3

virsh destroy hassio$TESTVERSION

sleep 3

virsh undefine hassio$TESTVERSION

cat <<'EOF'

You are now going to get a ton of output; it'll start with a bunch of stuff that mentions random Linux distros like Fedora; just ignore that.

After that you'll see virt-builder doing its setup, including grub updates to get the console working.

After that it'll roll directly into the console; ctrl-] to break out.

You can log in as root or rlpowell with test123 as the password.

Hit enter to continue.

EOF

read line

# Got some of this from https://frehberg.wordpress.com/2017/07/25/howto-virt-builder-debian-9-using-serial-console/
virt-builder debian-10 -v -x --output /var/lib/libvirt/images/hassio$TESTVERSION.raw --format raw --size 20G --root-password password:test123 --hostname hassio$TESTVERSION --edit '/etc/default/grub: s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0"/' --run-command '/usr/sbin/update-grub2' --firstboot /srv/hassio/hassio.run.sh
# --install "bind9,bind9-doc,dnsutils" 

virt-install --name hassio$TESTVERSION --import --ram 4096 --os-variant debian10 --autostart --disk /var/lib/libvirt/images/hassio$TESTVERSION.raw --graphics none --filesystem /srv/hassio/data-hassio-backups,hassio-backups --filesystem /srv/hassio/data-influxdb-backups,influxdb-backups --network bridge=br0 --autoconsole text
# --console pty,target.type=virtio --network bridge=br0 --autoconsole text

setenforce 1

cat <<EOF

Main script output is in ~root/virt-sysprep-firstboot.log on the host.

If necessary, you can view that from the outside with: sudo bash -c "export LIBGUESTFS_BACKEND=direct ; virt-cat -d hassio$TESTVERSION /root/virt-sysprep-firstboot.log"

Log in as rlpowell / test123

You can then use sudo, or su if sudo is broken (test123 is also the root password)

Update your password and root's password

Once you've logged in and checked that file, you have to REBOOT (to get the file system mounts working)

After you've rebooted and check the file system mounts, run this by hand (because it talks to the tty):

$ cd /usr/local/src
$ sudo bash installer.sh

(say yes to replacing /etc/network/interfaces)

After that runs:

$ sudo nmcli device modify enp3s0 ipv4.method manual ipv4.addresses '192.168.123.138/24' ipv4.gateway '192.168.123.254' ipv4.dns '192.168.123.254 8.8.8.8'

^^ Sometimes, for reasons I'm completely unclear on, the host's
networking will get broken after the final reboot below and you'll
have to console in as root and run that again.

Then:

$ sudo dpkg -i os-agent_*_linux_x86_64.deb

Influxdb restore:

$ sudo /usr/local/bin/influxdb_restore_latest

, which should say something about waffles_sensors at the very end.

Wait until http://192.168.123.138:8123/onboarding.html asks if you want to restore a backup, but don't.

Back on the hassio box:

$ cd /usr/share/hassio/backup/
$ ls -lrt

Pick a backup slug and:

$ sudo ha backups restore [slug]

Then:

$ sudo ha su repair
$ sudo ha host reboot

At that point, once it's back up, go to http://192.168.123.138:8123/hassio/system and see if it has any unsupported installation warnings.

You should also check the notifications at the bottom left.

EOF
