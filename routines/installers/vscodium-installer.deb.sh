#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")
source "$script_dir/../helper.sh"

verify_root

KEYRING_DIR=$(get_pkg_gpg_dir)
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | dd of="$KEYRING_DIR/vscodium-archive-keyring.gpg"

echo "deb [ signed-by=$KEYRING_DIR/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main" \
    | tee /etc/apt/sources.list.d/vscodium.list

apt update && apt install -y codium
