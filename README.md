# hassio-vm

Scripts for making a VM on Fedora 31 to run hass.io

## Sources

Here's various stuff I read online to get this orking, especially the first one:

https://community.home-assistant.io/t/set-up-hass-io-on-top-of-a-virtual-machine/42497

https://heiko-sieger.info/tuning-vm-disk-performance/

https://wiki.libvirt.org/page/Networking#Creating_network_initscripts

https://phoenixnap.com/kb/how-to-install-docker-on-ubuntu-18-04

https://dustymabe.com/2012/09/11/share-a-folder-between-kvm-host-and-guest/

http://rabexc.org/posts/p9-setup-in-libvirt

## Requirements

You need a bunch of KVM stuff for this to work; something like this:

        sudo dnf install @virtualization qemu-kvm virt-install virt-manager virt-viewer virt-builder libguestfs-tools

## How To Use

The scripts are specific to my setup; in particular they assume my domain of digitalkingdom.org and my local network of 192.168.123.0/24 and my username of rlpowell

Having said that, it's a pretty great start; if you fix the network and run these scripts, you'll get a VM that sends all its output to the console, has Docker installed and ready to go, and is just basically completely ready to run hass.io ; there's a command you have to run after you start the VM, but the script's output tells you what that is, too.

The VM will try to mount /srv/hassio/data to /usr/share/hassio, which if it works means that you can rebuild the VM at will and lose no data whatsoever.  For this to work, /srv/hassio/data needs to be owned by qemu:qemu, and the SELinux context needs to be `svirt_image_t`.
