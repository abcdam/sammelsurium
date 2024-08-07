#!/bin/dash
set -e
USERLIB=$(realpath ~/lib)
USERBIN=$(realpath ~/bin)
DLDIR=$(realpath ~/Downloads)
NAME="WebStorm-2024.1.5"
WBSLIB="$USERLIB/$NAME"

curl --output-dir "$DLDIR" -LO https://download.jetbrains.com/webstorm/$NAME.tar.gz

mkdir -p "$WBSLIB" 
tar -xzvf "$NAME.tar.gz" --strip-components=1 -C "$WBSLIB"
LAUNCHER="$WBSLIB/bin/webstorm.sh"
chmod +x "$LAUNCHER"
ln -s "$LAUNCHER" "$USERBIN/wbs"

output=$(which wbs)
rm -f "$DLDIR/$NAME.tar.gz"
[ -f "$output" ] && echo "webstorm can be started using 'wbs' command" && exit 0
echo "Add $USERBIN to PATH variable to make 'wbs' (webstorm launcher) callable everywhere"
