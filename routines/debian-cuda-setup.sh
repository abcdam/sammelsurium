#!/bin/bash
path="/etc/apt/keyrings/cuda-archive-keyring.gpg";
wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-archive-keyring.gpg
wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
mv cuda-archive-keyring.gpg $path


echo "deb [signed-by=${path}] https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/ /" | sudo tee /etc/apt/sources.list.d/cuda-debian11-x86_64.list