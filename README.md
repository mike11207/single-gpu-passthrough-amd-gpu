# single-gpu-passthrough-amd-gpu
This is a guide for passing an AMD GPU to a Windows 10 Guest VM on Linux

There are several outstanding guides covering this topic and you should check them out first If you have no idea about single gpu passthrough.

I decided to make my own guide because all of the guides already available didn't work for me because they were mostly ment for Nvidia GPUs.
After 2 months of troubleshooting I was finally able to make this setup work and hopefully this will work for you too.

This guide assumes you're using Arch Linux.

STEP 1 Enabling IOMMU in your BIOS

If you have an Intel CPU, enable VT-d and VT-x
If you have an AMD CPU, enable SVM Mode and IOMMU

once thats done you can move on with step 2:

STEP 2 Editing the boot parameters

If you use systemd-boot open this file /boot/loader/entries/arch.conf (This might not be arch.conf for you)
and edit the options line to look like this:
For AMD:

amd_iommu=on iommu=pt iommu=1 video=efifb:off
For Intel:

intel_iommu=on iommu=pt video=efif:off
Now Reboot your PC

STEP 3 Checking IOMMU Groups

To check if IOMMU is enabled enter this command and press enter:

dmesg | grep -i -e DMAR -e IOMMU

If you get a response youre good to go

STEP 4 INSTALL ALL TOOLS

enter this command and press enter:

sudo pacman -S virt-manager qemu vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf

STEP 5 EDIT CONFIG

edit this file:

/etc/libvirt/libvirtd.conf

Uncomment the # off the following lines:

unix_sock_group = "libvirt"

unix_sock_rw_perms = "0770"

add these line at the end of the file:

log_filters="1:qemu"
log_outputs="1:file:/var/log/libvirt/libvirtd.log"

Save the file and exit the editor

Now enter these commands (some of them are systemd specific):

sudo usermod -a -G libvirt $(whoami)
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

Now edit this file:

/etc/libvirt/qemu.conf

change
#user = "root" to user = "your username"
and
#group = "root" to group = "your username"

Now restart libvirt:

sudo systemctl restart libvirtd

To get networking working enter these commands:

sudo virsh net-autostart default
sudo virsh net-start default

STEP 6 CONFIGURE VIRTUAL MACHINE

Download the Windows 10 iso and the fedoraproject virtio drivers

open virt-manager and create a new VM

leave the vm name default

once you see the overview section select the customize before installation box

change the Firmware to /usr/share/edk2-ovmf/x64/OVMF_CODE.fd
uncheck the copy host CPU configuration box and set it to host passthrough
add the ISOs you downloaded and make sure you enable the CD ROM.
Change the virtual Network type to virtio and the disk type to virtio aswell
Now boot into Windows Installer. Once it says it cant find the disk press load driver and navigate to the virtio CD. The drivers are in the folder amd64/w10.
After that continue the bloatware install

STEP 7 PREPARATION FOR OUR SCRIPTS

Download the corresponding GPU vBios.
Either dump it yourself or find one on https://www.techpowerup.com/vgabios/

and enter mkdir /var/lib/libvirt/vbios in your terminal to make the directory for the vBios.
Now move the vBios in that folder and execute these commands:

chmod -R 660 <ROMFILE>.rom
chown username:username <ROMFILE>.rom
Now enter this script to get the IDs of the GPU

#!/bin/bash
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;

  You will want to find your GPU in there with its Audio component (if it has one)
  For me these IDs are:
  08:00.0
  and
  08:00.1
  
  Now go into virt-manager once more and add the parts of the GPU to the virtual machine
