#!/bin/bash
set -euxo pipefail

# virt-firmware.
# see https://pypi.org/project/virt-firmware
# see https://gitlab.com/kraxel/virt-firmware
VIRT_FIRMWARE_PIP_INSTALL_SPEC='virt-firmware==23.5'
VIRT_FIRMWARE_PIP_INSTALL_SPEC='git+https://gitlab.com/kraxel/virt-firmware.git@bf0912128c38684a19a0c530c18d6219a5f60ed9' # 2023-06-01T11:59:02Z

# install the dependencies.
# see https://github.com/pftf/RPi4/blob/v1.35/.github/workflows/linux_edk2.yml
apt-get install -y \
    acpica-tools gcc-aarch64-linux-gnu python3-distutils uuid-dev \
    build-essential dos2unix unzip zip
ln -fs /usr/bin/python{3,} # symlink python to python3.

# install virt-firmware.
apt-get install -y python3-pip
python3 -m pip install $VIRT_FIRMWARE_PIP_INSTALL_SPEC
