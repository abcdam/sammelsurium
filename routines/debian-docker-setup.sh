#!/bin/bash
script_dir=$(dirname "$(realpath "$0")")
source $script_dir/bash-lib.sh
# tightly following https://archive.is/HxU6M

is_root || throw "must be executed as root"
echo "delete old installs"
apt-get remove docker docker-engine docker.io containerd runc

echo "setup docker repo"

apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

mkdir -p /etc/apt/keyrings
keyring_path="/etc/apt/keyrings/docker.gpg"
file_exists $keyring_path \
  && echo "File $keyring_path already exists, skipping download. To replace it delete it manually first" \
  || curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o "$keyring_path"

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
echo "Installing docker packages"
apt-get install -y  \
    docker-ce       \
    docker-ce-cli   \
    containerd.io   \
    docker-compose-plugin
echo "Trying to run hello-world image..."
docker run hello-world
echo "script execution finished."
