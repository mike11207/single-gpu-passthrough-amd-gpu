# single-gpu-passthrough-amd-gpu
This is a guide for passing an AMD GPU to a Windows 10 Guest VM on Linux

EDIT:
Since I switched to an NVIDIA GPU I'll be throwing my new scripts in here too

I will not cover hugepages and CPU pinning in this guide because my performance is fine as it is.

There are several outstanding guides covering this topic and you should check them out first If you have no idea about single gpu passthrough.

I decided to make my own guide because all of the guides already available didn't work for me because they were mostly ment for Nvidia GPUs.
After 2 months of troubleshooting I was finally able to make this setup work and hopefully this will work for you too.

This guide assumes you're using Arch Linux.

## STEP 1 Enabling IOMMU in your BIOS

If you have an Intel CPU, enable VT-d and VT-x

If you have an AMD CPU, enable SVM Mode and IOMMU

once thats done you can move on with step 2:

## STEP 2 Editing the boot parameters

If you use grub edit /etc/default/grub and put the following under `GRUB_CMDLINE_LINUX_DEFAULT`

If you use systemd-boot open this file /boot/loader/entries/arch.conf (This might not be arch.conf for you)
and edit the options line to look like this:
### For AMD:

`amd_iommu=on iommu=pt iommu=1 video=efifb:off`

### For Intel:

`intel_iommu=on iommu=pt video=efif:off`


You might want to add this line which helps with black screen issues

`disable_idle_d3=1`

Now Reboot your PC

## STEP 3 Checking IOMMU Groups

To check if IOMMU is enabled enter this command and press enter:

`dmesg | grep -i -e DMAR -e IOMMU`

If you get a response youre good to go

## STEP 4 INSTALL ALL TOOLS

enter this command and press enter:

`pacman -S virt-manager qemu vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf`

## STEP 5 EDIT CONFIG

edit this file:

`/etc/libvirt/libvirtd.conf`

Uncomment the # off the following lines:

```
unix_sock_group = "libvirt"

unix_sock_rw_perms = "0770"
```

add these line at the end of the file:

```
log_filters="1:qemu"

log_outputs="1:file:/var/log/libvirt/libvirtd.log"
```

Save the file and exit the editor

Now enter these commands (some of them are systemd specific):

`sudo usermod -a -G libvirt $(whoami)`

`sudo systemctl start libvirtd`

`sudo systemctl enable libvirtd`

Now edit this file:

`/etc/libvirt/qemu.conf`

change `#user = "root"` to `user = "your username"`

and `#group = "root"` to `group = "your username"`

Now restart libvirt:

`sudo systemctl restart libvirtd`

To get networking working enter these commands:

`sudo virsh net-autostart default`
`sudo virsh net-start default`

## STEP 6 CONFIGURE VIRTUAL MACHINE

Download the [Windows 10 iso](https://www.microsoft.com/en-us/software-download/windows10ISO) and the [fedoraproject virtio drivers](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.160-1/)

open virt-manager and create a new VM

leave the vm name default

once you see the overview section select the customize before installation box

change the Firmware to `/usr/share/edk2-ovmf/x64/OVMF_CODE.fd`

uncheck the copy host CPU configuration box and set it to host passthrough

add the ISOs you downloaded and make sure you enable the CD ROM.

Change the virtual Network type to virtio and the disk type to virtio aswell

Now boot into Windows Installer. Once it says it cant find the disk press load driver and navigate to the virtio CD. The drivers are in the folder amd64/w10.

After that continue the bloatware install

## STEP 7 PREPARATION FOR OUR SCRIPTS

Download the corresponding GPU vBios.

Either dump it yourself using linux (amdvbflash for AMD nvflash for NVIDIA), GPU-Z using Windows or find one on https://www.techpowerup.com/vgabios/

and enter 
`mkdir /usr/share/vgabios` 
in your terminal to make the directory for the vBios.

Now move the vBios in that folder and execute these commands:

`chmod -R 660 ROM_NAME.rom`
`chown username:username ROM_NAME.rom`

Now enter this script to get the IDs of the GPU

```
#!/bin/bash
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
```

You can also find it here:

https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Prerequisites

  You will want to find your GPU in there with its Audio component (if it has one)
  
  For me these IDs are:
  
  `08:00.0`
  and
  `08:00.1`
  
  Now go into virt-manager once more and add the parts of the GPU to the virtual machine
  
  Go into your GPU in virt-manager and add this line:
  
  ```
  <source>
  <rom file="/var/lib/libvirt/vbios/GPU.rom"/>    <----THIS ONE
  <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
  ```
  
  Remove spice / qxl stuff in VM

enter these commands to make the hooks for our VM

```
mkdir -p /etc/libvirt/hooks

sudo wget 'https://raw.githubusercontent.com/PassthroughPOST/VFIO-Tools/master/libvirt_hooks/qemu' \
     -O /etc/libvirt/hooks/qemu
```
     
 and enter:
 
`sudo chmod +x /etc/libvirt/hooks/qemu`

Now you want to create these directories:

```
/etc/libvirt/hooks/qemu.d

/etc/libvirt/hooks/qemu.d/win10

/etc/libvirt/hooks/qemu.d/win10/prepare

/etc/libvirt/hooks/qemu.d/win10/prepare/begin

/etc/libvirt/hooks/qemu.d/win10/release

/etc/libvirt/hooks/qemu.d/win10/release/end
```

And make edit these files:

`/etc/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh`

It should be empty. Now just copy the start script uploaded by me into the file.

execute this command:

`chmod +x /etc/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh`

To make this script executable.

Next edit this file:

`/etc/libvirt/hooks/qemu.d/win10/release/end/revert.sh`

It should be empty. Now just copy the revert script uploaded by me into the file.

Execute this command:

`chmod +x /etc/libvirt/hooks/qemu.d/win10/release/end/revert.sh`

Now make another file in `/etc/libvirt/hooks/kvm.conf`

I remember from running the script earlier that the IDs of my GPU are 8:00.0 and 8:00.1 so I would need to enter:

`VIRSH_GPU_VIDEO=pci_0000_08_00_0`

`VIRSH_GPU_AUDIO=pci_0000_08_00_1`

Save the file and exit

## STEP 8 ENJOY YOUR WINDOWS GAMES

You are now ready to start the vm.

If you are having problems message me on Discord @ Mike12#2308 or create a Reddit post on [r/VFIO](https://old.reddit.com/r/VFIO/) and mention me in your post and I will try to help.
