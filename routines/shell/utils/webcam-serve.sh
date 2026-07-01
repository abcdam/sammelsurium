#!/bin/sh
set -e

[ $(id -u) -eq 0 ]

modprobe -r v4l2loopback
modprobe v4l2loopback       \
          exclusive_caps=1  \
          video_nr=0        \
          max_buffers=2     \
          card_label=Webcam

gphoto2 --stdout --capture-movie                  \
    | ffmpeg -hwaccel nvdec -c:v mjpeg_cuvid -i - \
          -vcodec rawvideo  \
          -pix_fmt yuv420p  \
          -stats            \
          -f v4l2 /dev/video0
