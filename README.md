# About

[![build](https://github.com/rgl/rpi4-uefi-ipxe/actions/workflows/build.yml/badge.svg)](https://github.com/rgl/rpi4-uefi-ipxe/actions/workflows/build.yml)

This builds UEFI iPXE for the Raspberry Pi 4 ARM64 and releases it with the [pftf/RPi4 binaries](https://github.com/pftf/RPi4).

This is used by [rgl/talos-vagrant](https://github.com/rgl/talos-vagrant) and is related to [rgl/raspberrypi-uefi-edk2-vagrant](https://github.com/rgl/raspberrypi-uefi-edk2-vagrant).

## sd-card flashing

Find which device was allocated for the sd-card that will store the uefi firmware:

```bash
lsblk -o KNAME,SIZE,TRAN,FSTYPE,UUID,LABEL,MODEL,SERIAL
# lsblk should output all the plugged block devices, in my case, this is the device that I'm interested in:
#
#   sde    28,9G usb                                                                STORAGE DEVICE   000000078
#   sde1    256M        vfat   9F2D-0578                            boot
#   sde2    6,1G        ext4   efc2ea8b-042f-47f5-953e-577d8860de55 rootfs
```

Wipe the sd-card (in this example its at `/dev/sde`) and put a release in it:

**NB** the rpi4 `recovery.bin` (which will end up inside the eeprom) bootloader only
supports booting from an MBR/MSDOS partition type/table/label and from a
FAT32 LBA (0x0c) or FAT16 LBA (0x0e) partition types/filesystem. Eventually
[it will support GPT](https://github.com/raspberrypi/rpi-eeprom/issues/126).

**NB** the rpi4 bootloader that is inside the [mask rom](https://en.wikipedia.org/wiki/Mask_ROM) also [seems to support GPT](https://github.com/raspberrypi/rpi-eeprom/issues/126#issuecomment-628719223), but until its supported by `recovery.bin` we cannot use a GPT.

```bash
# switch to root.
sudo -i

# set the sd-card target device and mount point.
target_device=/dev/sde
target=/mnt/rpi4-uefi

# umount any existing partition that you might have already mounted.
umount ${target_device}?

# format the sd-card at $target_device.
parted --script $target_device mklabel msdos
parted --script $target_device mkpart primary fat32 4 100
parted $target_device print
# Model: Generic STORAGE DEVICE (scsi)
# Disk /dev/sde: 31,0GB
# Sector size (logical/physical): 512B/512B
# Partition Table: msdos
# Disk Flags:
#
# Number  Start   End     Size    Type     File system  Flags
#  1      4194kB  2048MB  2044MB  primary  fat32        lba
mkfs -t vfat -n RPI4-UEFI ${target_device}1

# install the firmware in the sd-card.
mkdir -p $target
mount ${target_device}1 $target
# get the rpi4 uefi ipxe firmware.
wget https://github.com/rgl/rpi4-uefi-ipxe/releases/download/v0.1.0/rpi4-uefi-ipxe.zip
unzip rpi4-uefi-ipxe.zip -d $target

# check the results.
find $target

# eject the sd-card.
umount $target
eject $target_device

# exit the root shell.
exit
```

Remove the sd-card from the computer.

Put it in the rpi and power it up.

For more information see:

* [rgl/raspberrypi-uefi-edk2-vagrant](https://github.com/rgl/raspberrypi-uefi-edk2-vagrant).
* [rgl/talos-vagrant](https://github.com/rgl/talos-vagrant).
