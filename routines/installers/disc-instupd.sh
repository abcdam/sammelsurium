#!/bin/bash
# installs/updates discord to/in ~/lib/Discord
. /usr/lib/helper-func.sh
id=discord
URL="https://$id.com/api/download?platform=linux&format=tar.gz"
FILE="$id.tar.gz"
LIB="$HOME/lib"
PRODUCT_LIB="$LIB/$id"
cd /tmp
curl_o=$(curl -Lo "$FILE" "$URL")
[ $? -ne 0 ] && throw "err: download failed. curl output: '$curl_o'"
mkdir -p "$PRODUCT_LIB"
tar -xzf $FILE --strip-components=1 -C "$PRODUCT_LIB"
rm $FILE
echo 'Done.'