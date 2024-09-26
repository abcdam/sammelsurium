#!/bin/sh
# t(emplate)tmux: a script to launch tmux sessions according to specified templ.
#

. /usr/lib/helper-func.sh

SESH_ID=''
TPLATE_ID=''
WIN_ID=''

# window with 4 equisized panels
#
# A|B
#------
# C|D
#
default_template() {
    [ -z "$WIN_ID" ] && WIN_ID="gen_$(date +%m/%d_%H%M)"
    (tmux list-windows -t "$1" -F '#W' | grep -q "^$WIN_ID$") \
        && throw "error: window label '$WIN_ID' already in use for session '$1'."
    tmux new-window -t "$1" -n "$WIN_ID"
    tmux split-window -h -t "$1:$WIN_ID"
    tmux split-window -v -t "$1:$WIN_ID"
    tmux select-pane -t "$1:$WIN_ID.0"
    tmux split-window -v -t "$1:$WIN_ID"
}

while getopts "s:t:w:h" opt; do
  case $opt in
    s)
      SESH_ID=$OPTARG
      ;;
    t)
      TPLATE_ID=$OPTARG
      ;;
    w)
      WIN_ID=$OPTARG
      ;;
    h)
      synopsis && exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND -1))

[ -z "$TPLATE_ID" ] && TPLATE_ID='default'
printf '..%s..' "${SESH_ID}${WIN_ID}" | grep -q '[[:space:]]' \
    && throw "error: session name or window name contains spaces"
 

if ! (tmux ls -F '#S' | grep -q "$SESH_ID" >/dev/null 2>&1); then
    # exec sleep cmd in default window which will autokill it upon returning
    [ "$SESH_ID" ] && tmux new-session -d -s "$SESH_ID" "sleep 0.5"
    [ -z "$SESH_ID" ] && tmux new-session -d "sleep 0.5" \
        && SESH_ID=$(tmux display-message -p '#S')
fi

case "$TPLATE_ID" in
    default|0)
        default_template "$SESH_ID"
        ;;
    *)
        throw "error: Given template '$TPLATE_ID' not found"
        ;;
esac

tmux select-pane -t "$SESH_ID:$WIN_ID.0"
tmux attach-session -t "$SESH_ID:$WIN_ID"
