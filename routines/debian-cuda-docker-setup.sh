#!/bin/bash

# source https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

script_dir=$(dirname "$(realpath "$0")")
source $script_dir/bash-lib.sh

is_root || throw "must be executed as root"

keyring_path="/etc/apt/keyrings/nvidia-container-toolkit-keyring.gpg"
file_exists $keyring_path \
  && echo "File $keyring_path already exists, skipping download. To replace it delete it manually first" \
  || {
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o "$keyring_path";
      curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed "s#deb https://#deb [signed-by=${keyring_path}] https://#g" | \
          tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  }

apt update && \
  apt install -y nvidia-container-toolkit

nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

nvidia-smi --query-gpu=uuid,name --format=csv

echo "testing nvidia-container-toolkit installation"
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi