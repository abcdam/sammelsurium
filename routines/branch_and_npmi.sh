#!/bin/bash
NODE_VERSION=$(node -v)
ROOT_PATH=$PWD;

if [ -z "$REPID" ]; then
    echo "repo id not found at env var 'REPID'."
    exit 1;
fi

cd "/home/user/git/$REPID"

if [ $# -eq 0 ]; then
    echo "Error: Please provide a branch name."
    echo "Usage: $0 <branch_name>"
    exit 1
fi

branch="$1"

echo "Switching to branch '$branch'..."
git checkout "$branch"
if [ $? -ne 0 ]; then
    echo "Error: Failed to switch to branch '$branch'."
    exit 1
fi

echo "Running npm install..."

npm install
if [ $? -ne 0 ]; then
    echo "Error: npm install failed."
    exit 1
fi

echo "Branch setup finished."
