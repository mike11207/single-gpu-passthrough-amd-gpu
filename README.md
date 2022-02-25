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

It should look something like this

[    0.000000] Command line: initrd=\initramfs-linux.img root=/dev/sdb2 rw amd_iommu=on iommu=pt iommu=1 video=efifb:off
[    0.035105] Kernel command line: initrd=\initramfs-linux.img root=/dev/sdb2 rw amd_iommu=on iommu=pt iommu=1 video=efifb:off
[    0.283024] iommu: Default domain type: Passthrough (set via kernel command line)
[    0.302181] pci 0000:00:00.2: AMD-Vi: IOMMU performance counters supported
[    0.302205] pci 0000:00:01.0: Adding to iommu group 0
[    0.302212] pci 0000:00:01.2: Adding to iommu group 1
[    0.302219] pci 0000:00:02.0: Adding to iommu group 2
[    0.302228] pci 0000:00:03.0: Adding to iommu group 3
[    0.302235] pci 0000:00:03.1: Adding to iommu group 4
[    0.302242] pci 0000:00:04.0: Adding to iommu group 5
[    0.302249] pci 0000:00:05.0: Adding to iommu group 6
[    0.302258] pci 0000:00:07.0: Adding to iommu group 7
[    0.302263] pci 0000:00:07.1: Adding to iommu group 8
[    0.302272] pci 0000:00:08.0: Adding to iommu group 9
[    0.302279] pci 0000:00:08.1: Adding to iommu group 10
[    0.302289] pci 0000:00:14.0: Adding to iommu group 11
[    0.302295] pci 0000:00:14.3: Adding to iommu group 11
[    0.302316] pci 0000:00:18.0: Adding to iommu group 12
[    0.302322] pci 0000:00:18.1: Adding to iommu group 12
[    0.302327] pci 0000:00:18.2: Adding to iommu group 12
[    0.302332] pci 0000:00:18.3: Adding to iommu group 12
[    0.302338] pci 0000:00:18.4: Adding to iommu group 12
[    0.302344] pci 0000:00:18.5: Adding to iommu group 12
[    0.302350] pci 0000:00:18.6: Adding to iommu group 12
[    0.302356] pci 0000:00:18.7: Adding to iommu group 12
[    0.302369] pci 0000:01:00.0: Adding to iommu group 13
[    0.302377] pci 0000:01:00.1: Adding to iommu group 13
[    0.302384] pci 0000:01:00.2: Adding to iommu group 13
[    0.302387] pci 0000:02:00.0: Adding to iommu group 13
[    0.302391] pci 0000:02:02.0: Adding to iommu group 13
[    0.302394] pci 0000:02:03.0: Adding to iommu group 13
[    0.302397] pci 0000:05:00.0: Adding to iommu group 13
[    0.302404] pci 0000:06:00.0: Adding to iommu group 14
[    0.302411] pci 0000:07:00.0: Adding to iommu group 15
[    0.302436] pci 0000:08:00.0: Adding to iommu group 16
[    0.302445] pci 0000:08:00.1: Adding to iommu group 17
[    0.302452] pci 0000:09:00.0: Adding to iommu group 18
[    0.302461] pci 0000:0a:00.0: Adding to iommu group 19
[    0.302469] pci 0000:0a:00.1: Adding to iommu group 20
[    0.302476] pci 0000:0a:00.3: Adding to iommu group 21
[    0.302911] pci 0000:00:00.2: AMD-Vi: Found IOMMU cap 0x40
[    0.310999] perf/amd_iommu: Detected AMD IOMMU #0 (2 banks, 4 counters/bank).
[    2.491946] AMD-Vi: AMD IOMMUv2 loaded and initialized
