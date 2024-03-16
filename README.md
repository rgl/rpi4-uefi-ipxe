# About

[![build](https://github.com/rgl/rpi4-uefi-ipxe/actions/workflows/build.yml/badge.svg)](https://github.com/rgl/rpi4-uefi-ipxe/actions/workflows/build.yml)

This builds UEFI iPXE for the Raspberry Pi 4 ARM64 and releases it with the [pftf/RPi4 binaries](https://github.com/pftf/RPi4).

You can [flash it to a an sd-card](#sd-card-flashing).

Then, you can [try using iPXE](#ipxe-usage).

This is used by [rgl/talos-vagrant](https://github.com/rgl/talos-vagrant) and is related to [rgl/raspberrypi-uefi-edk2-vagrant](https://github.com/rgl/raspberrypi-uefi-edk2-vagrant).

## sd-card flashing

Use [Raspberry Pi Imager](https://github.com/raspberrypi/rpi-imager) or [Etcher](https://github.com/balena-io/etcher) to flash [a release `rpi4-uefi-ipxe.img.zip`](https://github.com/rgl/rpi4-uefi-ipxe/releases) file into the sd-card.

Alternatively, use the `rpi4-uefi-ipxe.zip` file to manually create the sd-card.

Find which device was allocated for the sd-card that will store the UEFI firmware:

```bash
lsblk -o KNAME,SIZE,TRAN,FSTYPE,UUID,LABEL,MODEL,SERIAL
# lsblk should output all the plugged block devices, in my case, this is the device that I'm interested in:
#
#   sde    28,9G usb                                                                STORAGE DEVICE   000000078
#   sde1    256M        vfat   9F2D-0578                            boot
#   sde2    6,1G        ext4   efc2ea8b-042f-47f5-953e-577d8860de55 rootfs
```

Wipe the sd-card (in this example its at `/dev/sde`) and put a release in it:

```bash
# switch to root.
sudo -i

# set the sd-card target device and mount point.
target_device=/dev/sde
target=/mnt/rpi4-uefi

# umount any existing partition that you might have already mounted.
umount ${target_device}?

# format the sd-card at $target_device.
parted --script $target_device mklabel gpt
parted --script $target_device mkpart ESP fat32 4MiB 100MB
parted --script $target_device set 1 esp on
mkfs -t vfat -F 32 -n RPI4-UEFI ${target_device}1

# show the details.
parted --script $target_device unit MiB print
# Model: Generic STORAGE DEVICE (scsi)
# Disk /dev/sde: 15268MiB
# Sector size (logical/physical): 512B/512B
# Partition Table: gpt
# Disk Flags:
#
# Number  Start    End      Size     File system  Name  Flags
#  1      4,00MiB  95,0MiB  91,0MiB  fat32        ESP   boot, esp
sfdisk -l $target_device
# Disk /dev/sde: 14,91 GiB, 16009658368 bytes, 31268864 sectors
# Disk model: STORAGE DEVICE
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes
# Disklabel type: gpt
# Disk identifier: 1B1E7509-88AF-4F42-9106-4CD120FD37C9
#
# Device     Start    End Sectors Size Type
# /dev/sde1   8192 194559  186368  91M EFI System

# install the firmware in the sd-card.
mkdir -p $target
mount ${target_device}1 $target
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

## iPXE Usage

When you see the UEFI firmware logo, press ESC to enter the Setup.

Select `Boot Manager`.

Select `SD/MMC on Arasan SDHCI`.

Press `Ctrl+B` to enter the iPXE command line.

Configure the network and the time:

```bash
dhcp
ntp pool.ntp.org
```

See the configuration:

```bash
config # press Ctrl+X to exit.
```

Try to download a file using HTTP and HTTPS:

```bash
# see https://ipxe.org/crypto
# see https://ipxe.org/cfg/crosscert
imgfetch http://boot.ipxe.org/1mb
imgfetch https://boot.ipxe.org/1mb
imgstat
imgfree 1mb # free one of the named fetched images.
imgfree     # free all.
```

Boot into the Debian Installer (https://www.debian.org/distrib/netinst):

**NB** Also see https://github.com/rgl/raspberrypi-uefi-edk2-vagrant/blob/master/rpi.ipxe.

```bash
dhcp
ntp pool.ntp.org
set b https://deb.debian.org/debian/dists/bookworm/main/installer-arm64/current/images/netboot/debian-installer/arm64
initrd ${b}/initrd.gz
kernel ${b}/linux
boot
```

Once Debian loads, press `Ctrl+Alt+F2`, type `free -m` to see the total memory. In my RPi4 with 8 GiB of RAM, this was the output:

```console
BusyBox v1.35.0 (Debian 1:1.35.0-4+b3) built-in shell (ash)
Enter 'help' for a list of built-in commands.

# free -m
          total      used      free     shared  buff/cache  available
Mem:    7984044     82956   7758700     129312      142388    7620596
Swap:         0         0         0
```

You can also try to boot into https://netboot.xyz:

**NB** Here, although the netboot.xyz menu loaded correctly, it failed to boot an actual OS.

```bash
chain --autofree https://boot.netboot.xyz
```

For more information see:

* [rgl/raspberrypi-uefi-edk2-vagrant](https://github.com/rgl/raspberrypi-uefi-edk2-vagrant).
* [rgl/talos-vagrant](https://github.com/rgl/talos-vagrant).
