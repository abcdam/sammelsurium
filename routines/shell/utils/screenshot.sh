#!/bin/dash
set -u

. $(get-posher)
load_posher yap

IMAGE_DIR="$HOME/Pictures"

while [ $# -gt 0 ]; do
  case $1 in
    -d|--dir)
      shift
      [ -d "${1:-=}" ]      \
      && SCRSHOT_DIR=$(abs_path "$1") \
      || throw "$0 -d|--dir invalid path '$1'"
      shift && break
      ;;
    *)
      throw "only -d|--dir flag accepted: $1"
      ;;
  esac
done

SCRSHOT_DIR="${SCRSHOT_DIR:-$IMAGE_DIR}/screenshots/$(date +%Y/%m)"




tmp_img=$(mktemp /tmp/sshot_XXXXXX.png)
add_exitrap "rm -f '$tmp_img'"


# --noopengl: suppress "failed to detect a compositor" opengl warning
o_err=$(maim --noopengl --format png --select 2>&1 >"$tmp_img")
ex_maim=$?
if [ $ex_maim -ne 0 ]; then
  case $o_err in *'Selection was cancelled by keystroke'*) exit 0;; esac
  throw "maim failed: $o_err" $ex_maim
fi

# eval "xdotool ..." => sets env:
# X=534
# Y=229
# SCREEN=0
# WINDOW=71303175
eval "$(xdotool getmouselocation --shell)"
win_name=$(echo "$tmp_win_name" | sed -E '
  s/(.*[^[:alnum:][:space:]])[[:space:]]*([[:alnum:][:space:]]+)$/\2_\1/; # swap trailing app name with context desc.
  s/[^[:alnum:][:space:]_]/ /g;  # special chars replaced with space
  s/[[:space:]]+/ /g; # collapse space sequences
  s/^ +| +$//g;
  s/ /-/g # join words with dash
')

img="$SCRSHOT_DIR/$(date +%d-%H%M%S)_${win_name}.png"
mkdir -p "$(dirname "$img")" || throw "failed to create dir for '$img'" $?

mv "$tmp_img" "$img"

xclip -selection clipboard -t image/png -i "$img"
