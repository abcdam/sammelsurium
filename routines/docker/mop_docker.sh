#!/bin/bash

. /usr/lib/helper-func.sh

show_help() {
    echo "Usage: $0 [-y] [-c] [-i] [-v] [-n] [-b]"
    echo ""
    echo "Options:"
    echo "  -y    run headless"
    echo "  -c    remove containers"
    echo "  -i    remove images"
    echo "  -v    remove volumes"
    echo "  -n    remove networks"
    echo "  -b    remove build cache"
    echo "  -h    show help message"
}

headless=false
remove_containers=false
remove_images=false
remove_volumes=false
remove_networks=false
remove_cache=false

while getopts "ycivnbhs:" opt; do
    case ${opt} in
        y|headless )
            headless=true
            ;;
        c|rm-containers )
            remove_containers=true
            ;;
        i|rm-images )
            remove_images=true
            ;;
        v|rm-volumes )
            remove_volumes=true
            ;;
        n|rm-networks )
            remove_networks=true
            ;;
        p|prune-cache )
            remove_cache=true
            ;;
        s|summarize )
            summary_resources="$OPTARG" && echo "$summary_resources" | grep -qE "^(i|d|c){1,3}$" || throw "err: only valid arguments to summarize are i, d, c."
            ;;
        h )
            show_help
            exit 0
            ;;
        \? )
            show_help
            exit 1
            ;;
    esac
done

if [ -n "$summary_resources" ]; then
    limit=$(printf "%s" "$summary_resources" | wc -c)
    i=1
    while true; do
        opt=$(printf "%s" "$summary_resources" | cut -c $i)
        case ${opt} in
            i) [ -z "$img" ]    && img=1    && docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}";;
            d) [ -z "$disk" ]   && disk=1   && docker system df;;
            c) [ -z "$contrs" ] && contrs=1 && docker ps -a --size;;
        esac
        i=$((i+1)) && [ $i -le $limit ] || break
    done
    exit 0
fi

# remove everything if nothing selected
if ! $remove_containers && ! $remove_images && ! $remove_volumes && ! $remove_networks && ! $remove_cache; then
    remove_containers=true
    remove_images=true
    remove_volumes=true
    remove_networks=true
    remove_cache=true
fi

# Print selection
LINE="--------------------------------------------------------"
if $remove_containers; then
    echo "# The following containers will be stopped and removed:"
    docker ps -a
    echo "$LINE"
fi

if $remove_images; then
    echo "# The following images will be removed:"
    docker images -a
    echo "$LINE"
fi

if $remove_volumes; then
    echo "# The following volumes will be removed:"
    docker volume ls
    echo "$LINE"
fi

if $remove_networks; then
    echo "# The following networks will be removed:"
    docker network ls
    echo "$LINE"
fi

[ -n "$remove_containers" ] && 
    echo "# Container space to be freed: $(docker system df --format '{{json .}}' | jq -r 'select(.Type == "Containers") | .Size')"

[ -n "$remove_images" ]     && 
    echo "# image space to be freed: $(docker system df --format '{{json .}}' | jq -r 'select(.Type == "Images") | .Size')"

[ -n "$remove_volumes" ]    && 
    echo "# volume space to be freed: $(docker system df --format '{{json .}}' | jq -r 'select(.Type == "Local Volumes") | .Size')"

[ -n "$remove_cache" ]      && 
    echo "# Build cache space to be freed: $(docker system df --format '{{json .}}' | jq -r 'select(.Type == "Build Cache") | .Size')"



# get user confirmation
if [ "$headless" = false ]; then
    read -p "Do you want to proceed with the cleanup? (y/n): " choice
    if [[ "$choice" != "y" ]]; then
        echo "Cleanup aborted."
        exit 1
    fi
fi

echo ""
##########################################################################3
if $remove_containers; then
    echo "# Stopping all running containers..."
    docker stop $(docker ps -q) > /dev/null 2>&1 || echo -e "\t...no container running."

    echo "# Removing all containers..."
    docker rm $(docker ps -aq) > /dev/null 2>&1 || echo -e "\t...no containers found to remove."
fi

if $remove_images; then
    echo "# Removing all images..."
    docker rmi $(docker images -q) > /dev/null 2>&1 || echo -e "\t...no images found to remove."
fi

if $remove_volumes; then
    echo "# Removing all volumes..."
    docker volume rm $(docker volume ls -q) > /dev/null 2>&1 || echo -e "\t...no volumes found to remove."
fi

if $remove_networks; then
    echo "# Removing all unused networks..." > /dev/null 2>&1 || echo -e "\t...no networks found to remove."
    docker network prune -f
fi

if $remove_cache; then
    echo "# Removing all build cache..." > /dev/null 2>&1 || echo -e "\tremoving build cache failed. Try manually: \n\n\t\tdocker builder prune -af"
    docker builder prune -af
fi

echo "Docker mopped."
echo -e "\n\n"
# Print summary
echo "# Summary of Docker resources remaining:"
echo "$LINE"
echo ""
echo "# Containers:"
docker ps -a
echo "$LINE"
echo "# Images:"
docker images
echo "$LINE"
echo "# Volumes:"
docker volume ls
echo "$LINE"
echo "# Networks:"
docker network ls
