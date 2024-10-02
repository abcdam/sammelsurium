#!/bin/sh
# t(emplate)tmux: a script to launch tmux sessions according to specified templ.
#

. /usr/lib/helper-func.sh
SESH_ID=''
TPLATE_ID=''
WIN_ID=''
DETACHED=''

default_template() {
  # window with 4 equisized panels
  #
  # A|B
  #------
  # C|D
  #
    _setup_sesh 'default'
    tmux new-window -t "$SESH_ID" -n "$WIN_ID"
    tmux split-window -h -t "$SESH_ID:$WIN_ID"
    tmux split-window -v -t "$SESH_ID:$WIN_ID"
    tmux select-pane -t "$SESH_ID:$WIN_ID.0"
    tmux split-window -v -t "$SESH_ID:$WIN_ID"
}


vExec_template() {
  # for each passed cmd, open a new pane on y-axis and exec cmd
  #
  # CMD_1
  #--------
  # CMD_2
  #--------
  # ...
  #--------
  # CMD_n
  #
    _setup_sesh 'exec'
    [ -z $1 ] && throw "error: no command passed."
    tmux new-window -t "$SESH_ID" -n "$WIN_ID" "$1"
    shift
    for cmd in "$@"; do
        tmux split-window -v -t "$SESH_ID:$WIN_ID" "$cmd"
    done
    tmux select-layout even-vertical
}

_setup_sesh() {
    default_winId="$1"
    _set_WINID "$default_winId"
    _set_SESHID
    (tmux list-windows -t "$SESH_ID" -F '#W' | grep -q "^$WIN_ID$") \
        && throw "error: window label '$WIN_ID' already in use for session '$SESH_ID'."
}

_set_WINID() {
    template_param="$1"
    [ -z "$WIN_ID" ] && WIN_ID="gen-${template_param}_$(date +%m/%d:%H%M)"
}

_set_SESHID() {
    if ! (tmux ls -F '#S' | grep -q "$SESH_ID" >/dev/null 2>&1); then
      if [ "$SESH_ID" ]; then
          # exec sleep cmd in default window which will autokill it upon returning
          tmux new-session -d -s "$SESH_ID" "sleep 0.5" \
          || throw "error: creating session with id '$SESH_ID' failed."
      else 
          tmux new-session -d "sleep 0.5" \
          && SESH_ID=$(tmux display-message -p '#S') \
          || throw "error: creating session with generic id failed."
      fi
    fi
}

while getopts "s:t:w:dh" opt; do
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
    d) 
      DETACHED=1
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

printf '..%s..' "${SESH_ID}${WIN_ID}" | grep -q '[[:space:]]' \
    && throw "error: session name or window name contains spaces"

[ -z "$TPLATE_ID" ] && TPLATE_ID='default'
case "$TPLATE_ID" in
    default|0)
        default_template
        ;;
    exec|1)
        vExec_template "$@"
        ;;
    *)
        throw "error: Given template '$TPLATE_ID' not found"
        ;;
esac

tmux select-pane -t "$SESH_ID:$WIN_ID.0"
[ -z $DETACHED ] && tmux attach-session -t "$SESH_ID:$WIN_ID"
