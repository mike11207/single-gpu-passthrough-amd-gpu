set -x

source "/etc/libvirt/hooks/kvm.conf"

systemctl stop display-manager

echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind


#uncomment the next line if you're getting a black screen
#echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

sleep 10

modprobe -r amdgpu
modprobe -r snd_hda_intel

virsh nodedev-detach $VIRSH_GPU_VIDEO
virsh nodedev-detach $VIRSH_GPU_AUDIO

sleep 10

modprobe vfio
modprobe vfio_pci
modprobe vfio_iommu_type1
