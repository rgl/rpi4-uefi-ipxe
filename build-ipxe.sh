#!/bin/bash
set -euxo pipefail

IPXE_VERSION='v1.21.1'      # see https://github.com/ipxe/ipxe/releases
RPI4_UEFI_VERSION='v1.29'   # see https://github.com/pftf/RPi4/releases

# clone the ipxe repo.
IPXE_PATH="$PWD/ipxe"
[ -d "$IPXE_PATH" ] || git clone https://github.com/ipxe/ipxe.git "$IPXE_PATH"

# build ipxe.
pushd "$IPXE_PATH"
git fetch origin master
git checkout $IPXE_VERSION

# configure.
# see https://ipxe.org/buildcfg/cert_cmd
# see https://ipxe.org/buildcfg/download_proto_https
# see https://ipxe.org/buildcfg/image_trust_cmd
# see https://ipxe.org/buildcfg/neighbour_cmd
# see https://ipxe.org/buildcfg/nslookup_cmd
# see https://ipxe.org/buildcfg/ntp_cmd
# see https://ipxe.org/buildcfg/param_cmd
# see https://ipxe.org/buildcfg/ping_cmd
# see https://ipxe.org/buildcfg/poweroff_cmd
# see https://ipxe.org/buildcfg
# see https://ipxe.org/appnote/named_config
cat >src/config/local/general.h <<'EOF'
#define CERT_CMD                /* Certificate management commands */
#define DOWNLOAD_PROTO_HTTPS    /* Secure Hypertext Transfer Protocol */
#define DOWNLOAD_PROTO_TFTP     /* Trivial File Transfer Protocol */
#define IMAGE_TRUST_CMD         /* Image trust management commands */
#define NEIGHBOUR_CMD           /* Neighbour management commands */
#define NSLOOKUP_CMD            /* Name resolution command */
#define NTP_CMD                 /* Network time protocol commands */
#define PARAM_CMD               /* Form parameter commands */
#define PING_CMD                /* Ping command */
#define POWEROFF_CMD            /* Power off command */
#undef SANBOOT_PROTO_AOE        /* AoE protocol */
EOF
# see https://ipxe.org/buildcfg/keyboard_map
cat >src/config/local/console.h <<'EOF'
// NB this has no effect in EFI mode. you must set the layout in the
//    efi firmware instead.
//#undef KEYBOARD_MAP
//#define KEYBOARD_MAP pt
EOF

# build.
# see https://ipxe.org/embed
# see https://ipxe.org/scripting
# see https://ipxe.org/cmd
# see https://ipxe.org/cmd/ifconf
# see https://ipxe.org/appnote/buildtargets
export CROSS_COMPILE=aarch64-linux-gnu-
NUM_CPUS=$((`getconf _NPROCESSORS_ONLN` + 2))
# NB sometimes, for some reason, when we change the settings at
#    src/config/local/*.h they will not always work unless we
#    build from scratch.
rm -rf src/bin*
time make -j $NUM_CPUS -C src bin-arm64-efi/ipxe.efi
popd

# package it.
RPI4_UEFI_PATH="$PWD/RPi4_UEFI_Firmware_$RPI4_UEFI_VERSION"
RPI4_UEFI_IPXE_ZIP_PATH="$PWD/rpi4-uefi-ipxe.zip"
RPI4_UEFI_IPXE_IMG_PATH="$PWD/rpi4-uefi-ipxe.img"
RPI4_UEFI_IPXE_IMG_ZIP_PATH="$PWD/rpi4-uefi-ipxe.img.zip"
# package it as a zip file.
[ -f "$RPI4_UEFI_PATH.zip" ] || wget -q "https://github.com/pftf/RPi4/releases/download/$RPI4_UEFI_VERSION/$(basename "$RPI4_UEFI_PATH").zip"
[ -d "$RPI4_UEFI_PATH" ] || unzip -d "$RPI4_UEFI_PATH" "$RPI4_UEFI_PATH.zip"
install -d "$RPI4_UEFI_PATH/efi/boot"
install "$IPXE_PATH/src/bin-arm64-efi/ipxe.efi" "$RPI4_UEFI_PATH/efi/boot/bootaa64.efi"
pushd "$RPI4_UEFI_PATH"
rm -f "$RPI4_UEFI_IPXE_ZIP_PATH"
zip -9 --no-dir-entries -r "$RPI4_UEFI_IPXE_ZIP_PATH" .
unzip -l "$RPI4_UEFI_IPXE_ZIP_PATH"
popd
# package it as a image zip file.
rm -f "$RPI4_UEFI_IPXE_IMG_PATH" "$RPI4_UEFI_IPXE_IMG_ZIP_PATH"
truncate --size $((100*1024*1024)) "$RPI4_UEFI_IPXE_IMG_PATH"
target_device="$(losetup --partscan --show --find "$RPI4_UEFI_IPXE_IMG_PATH")"
parted --script "$target_device" mklabel msdos
parted --script "$target_device" mkpart primary fat32 4 100%
mkfs -t vfat -n RPI4-IPXE "${target_device}p1" # NB vfat label is truncated to 11 chars.
target_path="$RPI4_UEFI_IPXE_IMG_PATH-boot"
mkdir -p "$target_path"
mount "${target_device}p1" "$target_path"
unzip "$RPI4_UEFI_IPXE_ZIP_PATH" -d "$target_path"
umount "$target_path"
rmdir "$target_path"
losetup --detach "$target_device"
zip -9 "$RPI4_UEFI_IPXE_IMG_ZIP_PATH" "$RPI4_UEFI_IPXE_IMG_PATH"
rm "$RPI4_UEFI_IPXE_IMG_PATH"
sha256sum rpi4-uefi-ipxe*.zip >sha256sum.txt

# copy to the host when running from vagrant.
if [ -d /vagrant ]; then
    mkdir -p /vagrant/tmp
    cp -f "$IPXE_PATH/src/bin-arm64-efi/ipxe.efi" /vagrant/tmp
    cp -f rpi4-uefi-ipxe*.zip sha256sum.txt /vagrant/tmp
fi
