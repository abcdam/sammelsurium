#!/bin/sh
set -e
src_f="$1" && shift
rustc "$src_f"
./$(basename --suffix .rs "$src_f") "$@"
