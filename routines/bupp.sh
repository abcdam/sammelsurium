#!/bin/bash
# bupp: back up provided path 
if [ -z "$1" ]; then
    echo "Usage: $0 <path|glob|directory>"
    exit 1
fi

if [ ! -e "$1" ]; then
    echo "Error - specified path '$1' does not exist."
    exit 1
fi
timestamp=$(date +"%Y%m%d%H%M%S")
base_name=$(basename "$1")

# generate backup dir
backup_dir="$HOME/${base_name}.${timestamp}.bupp"
mkdir -p "$backup_dir"

if cp -r "$1" "$backup_dir/"; then
    echo "back up at $backup_dir"
else
    echo "Error - cp -r failed  to create backup"
    exit 1
fi
