#!/bin/sh
SCRIPT_DIR=$(dirname "$0")
IMG_NAME=posix-sandbox

docker image inspect $IMG_NAME >/dev/null 2>&1 \
  || docker build -t $IMG_NAME "$SCRIPT_DIR"

[ -t 0 ] && t=
exec docker run --rm -i${t+t} $IMG_NAME ${@+"$@"}
