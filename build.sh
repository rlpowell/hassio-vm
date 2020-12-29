# run with "sudo bash -x" or similar

setenforce 0

virsh shutdown hassio

sleep 3

virsh destroy hassio

sleep 3

virsh undefine hassio

virt-builder ubuntu-18.04 -v --output /var/lib/libvirt/images/hassio.raw --format raw --size 20G --root-password password:test123 --hostname hassio --firstboot /srv/hassio/hassio.run.sh

virt-install --name hassio --import --ram 4096 --os-variant ubuntu18.04 --autostart --disk /var/lib/libvirt/images/hassio.raw --graphics none --filesystem /srv/hassio/data-hassio,hassio --filesystem /srv/hassio/data-influxdb,influxdb --console pty,target.type=virtio --network bridge=br0 --noautoconsole

setenforce 1

echo -e "\n\n\nMain script output is in ~root/virt-sysprep-firstboot.log on the host.\n\nLog in as rlpowell / test123\n\n\nOnce you've logged in and checked that file, you have to REBOOT (to get the file system mounts working)\n\n\nAfter you've rebooted and check the file system mounts, run this by hand (because it talks to the tty):\n\ncurl -sL https://raw.githubusercontent.com/home-assistant/supervised-installer/master/installer.sh | sudo bash -s && sudo ha su repair && sudo ha host reboot\n\n\n"
