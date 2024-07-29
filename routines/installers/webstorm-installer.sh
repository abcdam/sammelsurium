#!/bin/dash
USERLIB=/home/$(whoami)/lib
USERBIN=/home/$(whoami)/bin
NAME="WebStorm-2024.1.5"
WBSLIB="$USERLIB/$NAME"
cd /tmp/
wget https://download.jetbrains.com/webstorm/$NAME.tar.gz

mkdir -p "$WBSLIB" 
tar -xzvf "$NAME.tar.gz" --strip-components=1 -C "$WBSLIB"
ln -s "$WBSLIB/bin/webstorm.sh" $USERBIN/wbs

output=$(which wbs)
[ -f "$output" ] && echo "webstorm can be started using 'wbs' command". && exit 0
echo "Add $USERBIN to PATH variable to make 'wbs' (webstorm launcher) callable everywhere"
