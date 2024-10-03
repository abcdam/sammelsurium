#!/bin/sh
# Wrapper around docker to run python scripts in isolated environment.
#   Accepts path to py script + args if available
. /usr/lib/helper-func.sh
IMG=python:devenv
script=$(realpath $1)
shift
[ ! -f $script ] && throw "err: given script '$script' not a regular file."

script_dir=$(dirname $script)
script_id=$(basename $script)
# forward terminal size for adaptive plotext rendering
COLUMNS=$(tput cols) LINES=$(tput lines) docker run --rm \
    -e COLUMNS -e LINES \
    -v "$script_dir:/app" $IMG python /app/$script_id "$@"
