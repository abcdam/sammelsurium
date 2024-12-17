#!/bin/sh
# /app/project mounted by docker compose in this setup
/app/lib/RustRover/bin/remote-dev-server    \
    run /app/project/                       \
    --ssh-link-user $(whoami)               \