#!/bin/bash

# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/
#

apt install -y gcc  \ 
    build-essential \
    linux-headers-$(uname -r)

wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb

apt update && apt install -y \
    cuda

