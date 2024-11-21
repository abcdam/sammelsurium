#!/bin/bash

script_dir=$(dirname $(realpath "$0"))
source "$script_dir/../../helper.sh"

verify_root

# purge cuda and nvida driver from system
apt-get -y --purge remove \
    "*cuda*"        \
    "*cublas*"      \
    "*cufft*"       \
    "*cufile*"      \
    "*curand*"      \
    "*cusolver*"    \
    "*cusparse*"    \
    "*gds-tools*"   \
    "*npp*"         \
    "*nvjpeg*"      \
    "nsight*"       \
    "*nvvm*"        \
    "*nvidia*"      \
    "libxnvctrl*"

apt-get autoclean -y
apt-get autoremove -y