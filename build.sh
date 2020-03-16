virsh shutdown hassio

sleep 3

virsh destroy hassio

sleep 3

virsh undefine hassio

virt-builder ubuntu-18.04 -v --output /var/lib/libvirt/images/hassio.raw --format raw --size 20G --root-password password:test123 --hostname hassio --run /srv/hassio/hassio.run.sh

virt-install --name hassio --import --ram 4096 --os-variant ubuntu18.04 --autostart --disk /var/lib/libvirt/images/hassio.raw --graphics none --filesystem /srv/hassio/data,hassio --console pty,target.type=virtio --network bridge=br0
