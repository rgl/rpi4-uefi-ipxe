#!/bin/bash
set -euxo pipefail

# virt-firmware.
# see https://pypi.org/project/virt-firmware
# see https://gitlab.com/kraxel/virt-firmware
VIRT_FIRMWARE_PIP_INSTALL_SPEC='virt-firmware==25.12'
#VIRT_FIRMWARE_PIP_INSTALL_SPEC='git+https://gitlab.com/kraxel/virt-firmware.git@dc4d64c793823a4edee80c55726744ec48243211' # 2025-12-08T11:19:42Z

# install the dependencies.
# see https://github.com/pftf/RPi4/blob/v1.50/.github/workflows/linux_edk2.yml
apt-get install -y \
    acpica-tools gcc-aarch64-linux-gnu python3-pip python3-venv uuid-dev \
    build-essential dos2unix unzip zip
ln -fs /usr/bin/python{3,} # symlink python to python3.

# install venv.
python3 -m venv --system-site-packages /opt/venv
echo 'export PATH="/opt/venv/bin:$PATH"' >>~/.bash_login
export PATH="/opt/venv/bin:$PATH"

# install virt-firmware.
python3 -m pip install $VIRT_FIRMWARE_PIP_INSTALL_SPEC

# show the full path for the virt-fw-vars virt-firmware command.
which virt-fw-vars
