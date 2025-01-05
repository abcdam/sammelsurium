#!/bin/sh
name=python
tag=devenv
context="$(dirname $(realpath $0))"
echo "context: $context"
docker build -t $name:$tag "$context"
