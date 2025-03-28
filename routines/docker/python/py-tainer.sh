#!/bin/sh
# Wrapper around docker to run python scripts in isolated environment.
#   Accepts path to py script + args if available
. /usr/lib/helper-func.sh
IMG=python:devenv
if [ "$1" = 'build' ] && ! "$(get_dir_of $0)/build.sh"; then
    throw "err: building failed"
fi
script="$(realpath "$1")"
shift
[ ! -f "$script" ] && throw "err: given script '$script' not a regular file."

script_dir=$(dirname "$script")
script_id=$(basename "$script")
echo "Shared directory: $script_dir"
# - forward terminal size for adaptive plotext rendering
COLUMNS=$(tput cols) LINES=$(tput lines) docker run --rm -it \
    -e COLUMNS -e LINES \
    -w /app             \
    -v "$script_dir:/app" "$IMG" python "/app/$script_id" "$@"
