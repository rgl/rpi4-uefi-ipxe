#!/bin/bash
set -euxo pipefail

# virt-firmware.
# see https://pypi.org/project/virt-firmware
# see https://gitlab.com/kraxel/virt-firmware
VIRT_FIRMWARE_PIP_INSTALL_SPEC='virt-firmware==24.2'
#VIRT_FIRMWARE_PIP_INSTALL_SPEC='git+https://gitlab.com/kraxel/virt-firmware.git@84a16fe2907ef56a2609e7bfa8235a85bcf2f59e' # 2024-02-15T22:56:01+01:00

# install the dependencies.
# see https://github.com/pftf/RPi4/blob/v1.36/.github/workflows/linux_edk2.yml
apt-get install -y \
    acpica-tools gcc-aarch64-linux-gnu python3-distutils uuid-dev \
    build-essential dos2unix unzip zip
ln -fs /usr/bin/python{3,} # symlink python to python3.

# install virt-firmware.
apt-get install -y python3-pip
python3 -m pip install $VIRT_FIRMWARE_PIP_INSTALL_SPEC
