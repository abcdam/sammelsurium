#!/bin/sh
# Wrapper around docker to run python scripts in isolated environment.
#   Accepts path to py script + args if available
IMG=python:devenv
script=$(realpath $1)
shift
[ ! -f $script ] && throw "err: given script '$script' not a regular file."

script_dir=$(dirname $script)
script_id=$(basename $script)
docker run --rm -v "$script_dir:/app" $IMG python /app/$script_id "$@"
