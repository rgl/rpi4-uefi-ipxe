#!/bin/bash
set -euxo pipefail

# virt-firmware.
# see https://pypi.org/project/virt-firmware
# see https://gitlab.com/kraxel/virt-firmware
VIRT_FIRMWARE_PIP_INSTALL_SPEC='virt-firmware==23.11'
VIRT_FIRMWARE_PIP_INSTALL_SPEC='git+https://gitlab.com/kraxel/virt-firmware.git@1b7677e533150da71ed2960b7758e161e1ec6504' # 2023-11-30T12:31:51Z

# install the dependencies.
# see https://github.com/pftf/RPi4/blob/v1.35/.github/workflows/linux_edk2.yml
apt-get install -y \
    acpica-tools gcc-aarch64-linux-gnu python3-distutils uuid-dev \
    build-essential dos2unix unzip zip
ln -fs /usr/bin/python{3,} # symlink python to python3.

# install virt-firmware.
apt-get install -y python3-pip
python3 -m pip install $VIRT_FIRMWARE_PIP_INSTALL_SPEC
