#!/bin/dash
#
# Structured workaround to install compatible nvidia driver, container toolkit, and dependencies without package managers.
# This is needed to quickly enable cuda powered docker containers, to up- or downgrade the nvidia driver, and to extend one's lifespan owing to the fact that the official documentation and tool distribution is one clusterfuck.
#
# 
script_dir=$(dirname $(realpath "$0"))
source "$script_dir/../../helper.sh"

verify_root


usage() {
    echo "Usage: $0 [-d] [-c] [-t] [-y] [-h]"
    echo ""
    echo "Options:"
    echo "  -p    probe installed driver to check if a compatible cuda framework exists."
    echo -e "  -d    install a specific gpu driver. The script will show a list of possible versions and prompt for a selection.\n\t  If -p flag is set, it will skip the driver installation part and continue with the nvidia-container-toolkit installation"
    echo "  -l    list all driver versions that are supported by some cuda framework release"
    echo "  -h    show usage"
}

driver=''
probe=''
list=''

while getopts "pdlh" opt; do
    case ${opt} in
        p )
            probe=true # if set, the driver will be installed too
            ;;
        d )
            driver=true
            ;;
        l )
            list=true
            ;;
        h )
            usage
            exit 0
            ;;
        \? )
            usage
            exit 1
            ;;
    esac
done

[ ! $probe ] && [ ! $driver ] && [ ! $list ] && \
    usage && throw "No flags provided"

echo ""
echo "The script will attempt to automatically install the latest compatible modules according to the selected version and flags:"


# Extract list of driver versions that are compatible wth specific cuda container versions according to nvidia 
DRIVER_VERSIONS="$(curl --silent https://developer.download.nvidia.com/compute/cuda/redist/nvidia_driver/linux-x86_64/ | sed -n "s/.*-\([0-9]*\.[0-9]*\(\.[0-9]*\)\?\)-.*/\1/p")"

set -- $DRIVER_VERSIONS
echo ""
i=1
for version in "$@"; do
    printf "%2s) %s\n" $i $version
    i=$((i + 1))
done
echo ""
printf '%s' "Select the driver on which the installation will be based [1-$#]: "
read choice

[ "$choice" -lt 1 ] || [ "$choice" -gt $# ] && throw "Invalid selection."

echo "DEBUG: $choice"


#TODO call subscripts according to user flags and version selection