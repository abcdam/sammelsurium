#!/bin/dash
. $(get-posher)
load_posher yap file
IMAGE_DIR="$HOME/Pictures"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -d|--dir)
      shift
      [ -n "$1" ] && [ -d "$1" ]            \
      && SCRSHOT_DIR="$(abs_path "$1")"     \
      || throw "$0 -d|--dir requires a valid dir path"
      shift && break
      ;;
    *)
      throw "only -d|--dir flag accepted: $1"
      ;;
  esac
done

SCRSHOT_DIR="${SCRSHOT_DIR:-$IMAGE_DIR}/screenshots"




tmp_img_f="$(mktemp /tmp/sshot_XXXXXX.png)"
tmp_err_f="$(mktemp /tmp/maim_err_XXXXXX.txt)"
add_exitrap "rm -f '$tmp_img_f' '$tmp_err_f'"


# --noopengl: suppress "failed to detect a compositor" opengl warning
maim --noopengl --format png --select >"$tmp_img_f" 2>"$tmp_err_f" || ex_code=$?
if ! [ "${ex_code:-0}" -eq 0 ]; then
  if err_msg="$(grep --quiet --invert-match 'Selection was cancelled by keystroke' "$tmp_err_f")"; then
    throw "maim failed: $err_msg" "$ex_code"
  else exit 0
  fi
fi

# eval "xdotool ..." => sets env:
# X=534
# Y=229
# SCREEN=0
# WINDOW=71303175
eval "$(xdotool getmouselocation --shell)"

win_name="$(xdotool getwindowname "$WINDOW" | sed -E '
  s/[^[:alnum:][:space:]]/-/g;  # special chars replaced with dash
  s/[[:space:]]+/ /g;
  s/(.*)-(.*)$/\2_\1/;          # swap trailing app name with context desc.
  s/^ +| +$//g;
  s/ /_/g
')"

year_month_dir="$(date +%Y/%m)"
day_time_stamp="$(date +%d-%H%M%S)"
img_fname="${day_time_stamp}_${win_name}.png"

out_dir="$SCRSHOT_DIR/$year_month_dir"
mkdir -p "$out_dir" || throw "failed to create dir '$out_dir'"
out="$out_dir/$img_fname"

mv "$tmp_img_f" "$out"

xclip -selection clipboard -t image/png -i "$out"
