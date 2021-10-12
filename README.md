# hassio-vm

Scripts for making a VM on Fedora 34 to run hass.io

## Sources

Here's various stuff I read online to get this orking, especially the first two:

https://community.home-assistant.io/t/set-up-hass-io-on-top-of-a-virtual-machine/42497

https://community.home-assistant.io/t/installing-home-assistant-supervised-on-debian-11/200253

https://heiko-sieger.info/tuning-vm-disk-performance/

https://wiki.libvirt.org/page/Networking#Creating_network_initscripts

https://phoenixnap.com/kb/how-to-install-docker-on-ubuntu-18-04

https://dustymabe.com/2012/09/11/share-a-folder-between-kvm-host-and-guest/

http://rabexc.org/posts/p9-setup-in-libvirt

## Installation Method

See README-INSTALL-METHODS.txt

## Requirements

You need a bunch of KVM stuff for this to work; something like this:

        sudo dnf install @virtualization qemu-kvm virt-install virt-manager virt-viewer virt-builder libguestfs-tools iputils

You'll need to have bridge networking setup to use this the way I have it configured; if you just want to use NAT instead, remove all the network configuration / netplan stuff from hassio.run.sh and drop the --network option from build.sh and it'll *probably* just work; I just don't like NAT inside my network.

If you want to do bridge networking (i.e. VM networking without NAT), you can find docs online; for example https://docs.fedoraproject.org/en-US/Fedora/13/html/Virtualization_Guide/sect-Virtualization-Network_Configuration-Bridged_networking_with_libvirt.html

## How To Use

This will create "hassio3"; if you just want "hassio" then leave TESTVERSION unset:

$ sudo bash -c "cd $(pwd) ; export TESTVERSION=3 ; bash -x ./build.sh"

The scripts are specific to my setup; in particular they assume my domain of digitalkingdom.org and my local network of 192.168.123.0/24 and my username of rlpowell

Having said that, it's a pretty great start; if you fix the network and run these scripts, you'll get a VM that sends all its output to the console, has Docker installed and ready to go, and is just basically completely ready to run hass.io ; there's some commands you have to run after you start the VM, but the script's output tells you about them, too.

The VM will try to mount /srv/hassio/data-hassio-backups to /usr/share/hassio/backup, which is used to store backups that are run out of cron daily.  For this to work, /srv/hassio/data-hassio-backups needs to be owned by qemu:qemu, and the SELinux context needs to be `svirt_image_t`.

Same for /srv/hassio/data-influxdb-backups mounting to /var/lib/influxdb/backups .
