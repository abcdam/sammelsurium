#!/usr/bin/bash

if [ -z "$HOME" ] || [ -z "$REPID" ] || [ -z "$USR" ]; then
    echo "set HOME (is $HOME), USR (user)(is $USR), and REPID (repo name)(is $REPID) env vars before cloning"
    exit 187;
fi

eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/id_rsa"

git clone "git@github.com:$USR/$REPID.git" "$HOME/git/$REPID"

