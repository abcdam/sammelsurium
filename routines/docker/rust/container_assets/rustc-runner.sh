#!/bin/sh
set -e
# while getopts "c" opt; do
#     case ${opt} in
#         c) clean_up=1;;
#         \?) echo "err: unknown option '$opt'." 2>&1 && exit 1
#     esac
# done
# shift $((OPTIND -1))
src_f="$1" && shift
rustc "$src_f"
./$(basename --suffix .rs "$src_f") "$@"
