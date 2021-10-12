The list of official installation methods is at https://www.home-assistant.io/installation/

We're running the supervised method, per
https://community.home-assistant.io/t/installing-home-assistant-supervised-on-debian-11/200253
and
https://www.home-assistant.io/installation/linux#install-home-assistant-supervised
, and we should probably go do that at some point.

Our current method is based on restoring from an actual Home
Assistant backup (and a backup of influxdb as well).  Our previous
method was based on sharing the data directories for Home Assistant
and influxdb into the VM.  Doing it with backups makes rebuilding
slightly more effort, but it means we can cleanly upgrade much more
easily.

NOTE: Technically our build is unsupported (although
http://192.168.123.138:8123/hassio/system has no complaints) for two
reasons:
- We're running influxdb in the VM
- virt-builder doesn't have a Debian 11 install as of Oct 2021, but
  that's the only supported Linux for HomeAssistant Supervised. I
  could certainly do it with an ISO, but can't be bothered, so we
  should retry with debian-11 at some point.

Below are other methods we've tried.

- ------------------------------------------------

HassOS VM, Try 1:

For a while I was trying to do a full Home Assistant OS in a VM install.  This gives you a weird half-assed OS (it uses https://buildroot.org/ ), but it at least has docker.

If you decided to get this working, you'd want to do something like https://community.home-assistant.io/t/complete-guide-on-setting-up-grafana-influxdb-with-home-assistant-using-official-docker-images/42860 too

This worked for getting a running VM; I have not carefully gone over this command in detail:

$ sudo setenforce 0 ; sudo virt-install --name test-hass --import --boot uefi --ram 4096 --vcpus 4 --os-variant generic --disk /tmp/hassos_ova-5.9.qcow2 --graphics vnc --console pty,target.type=virtio --network bridge=br0

Reaching it:

$ sudo virsh dumpxml test-hass
$ sudo ncat --sh-exec "ncat localhost 5900" 192.168.123.137 -l 5900 --keep-open
, then run tightvnc

Cleanup:

$ sudo virsh destroy test-hass
$ sudo virsh undefine --nvram test-hass

- ------------------------------------------------

HassOS VM, Try 2:

Later on, I managed to get somewhat further, and in particular got
to the point of having SSH root access on the HassOS VM in LVM,
which honestly is a great starting point and if we were doing things
over again that'd probably be the way to go.

Given how much we've built around the supervised method, though, it
doesn't really seem worth it, but here's how far I got:

    $ sudo wget https://github.com/home-assistant/operating-system/releases/download/6.4/haos_ova-6.4.qcow2.xz

^^ Unpack that, stick it in /var/lib/libvirt/images/haos_ova-6.4.qcow2

    $ sudo virt-install --name hassio2 --import --ram 4096 --autostart --disk haos_ova-6.4-1.qcow2 --graphics none --console pty,target.type=virtio --network bridge=br0 --autoconsole text --boot uefi --os-variant linux2020

This was enough to get it running.  To access it I had to go to
http://homeassistant.local:8123/ in a *Windows* browser (whatever DNS
magic is happening there, our Linux isn't set up for it), and from the
config screen there I was able to get the host IP.

Then I read
https://developers.home-assistant.io/docs/operating-system/debugging/ ,
which is about how to get SSH on the box, and I thought to myself, yeah,
we could fake a USB key on the VM, but I bet we could just figure out
where the authorized_keys file *actually goes*.

Bunch of playing with virt-copy-in and virt-ls and guestfish and I did, in fact, get that working; it *does* have to be on the alternate port, so:

    $ ssh -p 22222 root@192.168.123.194 

or whatever.

WRT Guestfish and friends (most of the virt-copy virt-ls etc stuff is
actually guestfish wrappers, turns out), note that the VM consists of
like 8 layers of partitions; it's nuts.

But anyway, this seemed to work:

    $ sudo guestfish -a /var/lib/libvirt/images/haos_ova-6.4.qcow2
    ><fs> mount /dev/sda7 /
    ><fs> ls /
    etc
    lost+found
    root
    var
    ><fs> ls /root/
    .docker
    .ssh
    ><fs> find /root/
    .docker
    .ssh
    ><fs> vi /root/.ssh/authorized_keys
    libguestfs: error: download: /root/.ssh/authorized_keys: No such file or directory
    ><fs> ls /root/.ssh/
    ><fs> touch /root/.ssh/authorized_keys
    ><fs> vi /root/.ssh/authorized_keys

Next steps would be to get influxdb installed and get the shared
directory stuff working, I guess.
