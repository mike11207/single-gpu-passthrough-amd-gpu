#!/bin/bash
set -x

modprobe -r vfio
modprobe -r vfio_pci 
modprobe -r vfio_iommu_type1

# Re-Bind GPU to Nvidia Driver
virsh nodedev-reattach pci_0000_04_00_1
virsh nodedev-reattach pci_0000_04_00_0

#modprobe nouveau

# Reload nvidia modules
modprobe nvidia

# Rebind VT consoles
#echo 1 > /sys/class/vtconsole/vtcon0/bind
# Some machines might have more than 1 virtual console. Add a line for each corresponding VTConsole
#echo 1 > /sys/class/vtconsole/vtcon1/bind

#nvidia-xconfig --query-gpu-info > /dev/null 2>&1
#echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

systemctl start display-manager