setxkbmap $(setxkbmap -query | awk '$1=="layout:"{print $2=="ch"?"us":"ch";exit}')
