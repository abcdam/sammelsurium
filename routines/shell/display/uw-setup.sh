#!/bin/sh

$(xrandr | awk '
  / connected/ { port = $1; next }
  port && /^[[:space:]]/ {
    split($1, size, "x")
    if (size[1] > max_w) { max_w = size[1]; res = $1 }
    next
  }
  port { exit }
  END {
    if (port && res) { print "xrandr --output " port " --mode " res }
  }
')
feh --bg-scale ~/lib/sysasset/mt_uw_5120x1440.jpg
