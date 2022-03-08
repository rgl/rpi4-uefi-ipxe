#!/bin/bash
set -euxo pipefail

# install the dependencies.
# see https://github.com/pftf/RPi4/blob/v1.33/.github/workflows/linux_edk2.yml
apt-get install -y \
    acpica-tools gcc-aarch64-linux-gnu python3-distutils uuid-dev \
    build-essential dos2unix unzip zip
ln -fs /usr/bin/python{3,} # symlink python to python3.
