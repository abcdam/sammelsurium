# TODO make old driver install script version agnostic and incorporate it here

#!/bin/bash
# set -e

# if [ "$EUID" -ne 0 ]; then
#   echo "This script must be run as root :("
#   exit 1
# fi

# driver_version="550.100"
# driver_name="NVIDIA-Linux-x86_64-${driver_version}"
# OS=debian

# echo "Downloading proprietary NVIDIA driver.."

# wget https://us.download.nvidia.com/XFree86/Linux-x86_64/550.100/${driver_name}.run

# echo "Making installer executable.."
# chmod +x NVIDIA-Linux-x86_64-550.100.run

# # install all dependencies
# echo "Installing driver dependencies:"
# apt install -y                  \
#     pkg-config                  \
#     build-essential             \
#     linux-headers-$(uname -r)   \
#     libglvnd-dev

# echo "Running customized driver installer without building kernel modules.."
# ./${driver_name}.run   \
#     --keep                          \
#     --no-nouveau-check              \
#     --no-disable-nouveau            \
#     --no-x-check                    \
#     --no-kernel-modules             \
#     --silent                        \
#     --no-rebuild-initramfs

# cd ${driver_name}/kernel

# echo "Ruilding kernel modules"
# # for now, no special build arguments
# make

# kernel_driver_path=/lib/modules/$(uname -r)/kernel/drivers/video/
# echo "Move nvidia kernel modules without peermem to $kernel_driver_path..."
# kernel_nvidia_modules=$(ls | grep -v "peermem" | grep  -E nvidia.*.?ko)
# mv $kernel_nvidia_modules $kernel_driver_path

# # probe all available modules
# depmod -a

# echo "Backing up grub default config to home dir.."
# cp /etc/default/grub $HOME/

# # block open source nvidia driver in bootloader
# echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX rd.driver.blacklist=nouveau"' >> /etc/default/grub

# # enable special driver features
# echo "Enabling modeset and fbdev feature flags"
# feature_config_path=/etc/modprobe.d/nvidia-custom-flags.conf 
# touch $feature_config_path
# echo "options nvidia-drm modeset=1 fbdev=1" >> $feature_config_path

# echo "Rebuilding grub configuration in UEFI mode.."
# grub-mkconfig -o /boot/efi/EFI/${OS}/grub.cfg

# echo "Updating initramfs.."
# update-initramfs -u