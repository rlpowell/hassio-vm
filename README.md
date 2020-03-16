# hassio-vm

Scripts for making a VM on Fedora 31 to run hass.io

You need a bunch of KVM stuff for this to work; something like this:

        sudo dnf install @virtualization qemu-kvm virt-install virt-manager virt-viewer virt-builder libguestfs-tools

The scripts are specific to my setup; in particular they assume my domain of digitalkingdom.org and my local network of 192.168.123.0/24 and my username of rlpowell

Having said that, it's a pretty great start; if you fix the network and run these scripts, you'll get a VM that sends all its output to the console, has Docker installed and ready to go, and is just basically completely ready to run hass.io ; there's a command you have to run after you start the VM, but the script's output tells you what that is, too.

The VM will try to mount /srv/hassio/data to /usr/share/hassio, which if it works means that you can rebuild the VM at will and lose no data whatsoever.  For this to work, /srv/hassio/data needs to be owned by qemu:qemu, and the SELinux context needs to be `svirt_image_t`.
