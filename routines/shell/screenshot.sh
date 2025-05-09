#!/bin/dash
. $(get-posher)
load_posher yap
SCRSHOT_DIR_DEFAULT="$HOME/Pictures/Screenshots"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -d|--dir)
      shift
      [ -n "$1" ] && [ -d "$1" ]            \
      && SCRSHOT_DIR="$(realpath $1)" && shift && break \
      || throw "$0 -d|--dir requires a valid dir path"
      ;;
    *)
      throw "only -d|--dir flag accepted: $1"
      ;;
  esac
done

[ -z "$SCRSHOT_DIR" ] && SCRSHOT_DIR="$SCRSHOT_DIR_DEFAULT"
tmpfile="$(mktemp /tmp/sshot_XXXXXX.png)"
maim --format png --select > "$tmpfile" 2>/dev/null || throw "failed to run maim"

# xdotool getmouselocation --shell => sets env:
# X=534
# Y=229
# SCREEN=0
# WINDOW=71303175
#
eval "$(xdotool getmouselocation --shell)"

win_name="$(xdotool getwindowname "$WINDOW" | sed -E '
  s/[^[:alnum:][:space:]]/-/g;  # special chars replaced with dash
  s/[[:space:]]+/ /g;
  s/(.*)-(.*)$/\2-\1/;          # swap trailing app name with context desc.
  s/^ +| +$//g;
  s/ /_/g
')"

stamp="$(date +%Y%m%d_%H%M%S)"
out="$SCRSHOT_DIR/${stamp}_${win_name}.png"

mv "$tmpfile" "$out"

xclip -selection clipboard -t image/png -i "$out"
