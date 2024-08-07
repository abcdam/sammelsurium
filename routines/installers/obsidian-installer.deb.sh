#!/bin/sh
set -e

LATEST_RELINFO=https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest
TARGET=$(curl --silent $LATEST_RELINFO | grep  -oE 'https.*-([[:digit:]]\.){3}(tar\.gz)')
VERSION=$(printf "$TARGET" | grep -oE '([[:digit:]]\.){2}[[:digit:]]' | tail -n1)
NAME="obsidian-$VERSION"
[ "$NAME" -eq "obsidian-" ] && printf "%s\n" "Failed to extract Version from download url: '$TARGET'" && exit 1
NAME_ARCHIVE="$NAME.tar.gz"
DL_DIR=$(realpath ~/Downloads)
LIB_DIR=$(realpath ~/lib)
BIN_DIR=$(realpath ~/bin)

curl --output-dir "$DL_DIR" -LO "$TARGET"
tar -C $LIB_DIR -xf "$DL_DIR/$NAME_ARCHIVE"

BINARY="$LIB_DIR/$NAME/obsidian"
chmod +x "$BINARY"
ln -s "$BINARY" "$BIN_DIR/obs"


