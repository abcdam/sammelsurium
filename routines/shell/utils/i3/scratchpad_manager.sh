#!/bin/dash

#
# Treat i3 containers like a second layer of dynamic workspaces
#   - Supports 10 scratchpad namespaces, mirroring i3's workspaces setup
#   - `marker` toggle that operates on focused containers
#               -> alternates between scratchpad de/registration
#   - `visibility` toggle that operates globally on marked containers
#               -> makes all tagged containers in/visible according to ns id
# @abcdam 2025/09
#
USAGE="Usage: $0 marker=[0-9] | visibility=[0-9]"

. $(get-posher)
load_posher yap

### HELPER
ipc()         { i3-msg ${1:?'missing args to i3-msg'}; }

mark_exists() { ipc "${2:-} -t get_marks" 2>/dev/null | grep -q "\"$1\""; }
stop_float()  { ipc "$1 floating disable";  }
has_mark()    { mark_exists "$1" 'focus';   }
v_toggle()    { ipc "$1 scratchpad show";   }
unmark()      { ipc "$1 unmark $2";         }
mark()        { ipc "mark $1";              }
pshh()        { "$@" >/dev/null 2>&1;       }
## END HELPER

### FUN
marker() {
  mark_id="$1"; target_id="$2"
  err_postf="with mark '${mark_id}'"
  ft='failed to'
  if has_mark "$mark_id"; then
    pshh stop_float $target_id                        \
      || throw "$ft disable floating mode for container $err_postf"
    pshh unmark "$target_id" "$mark_id"               \
      || throw "$ft unmark container $err_postf"
  else
    pshh mark "$mark_id"                              \
      || throw "$ft apply mark $err_postf"
    pshh ipc "move scratchpad"                        \
      || throw "$ft move scratchpad $err_postf"
    pshh v_toggle $target_id                          \
      || throw "$ft show scratchpad $err_postf"
  fi
  return 0
}

visibility() { mark_exists "$1" && pshh v_toggle "$2" || true; }
## END FUN

### INPUT VALIDATION
case "$1" in
    *=*)  action=${1%%=*}
          keyboard_digit=${1#*=}
    ;;
      *)  throw "$USAGE"
    ;;
esac
scratchpad_id=
target_id=
case $keyboard_digit in
  [0-9])  scratchpad_id="mark_${keyboard_digit}"
          target_id="[con_mark=${scratchpad_id}]"
    ;;
      *)  throw "$USAGE - not a digit '$keyboard_digit'"
    ;;
esac
case "$action" in marker|visibility)
    ;;
      *)  throw "$USAGE - unknown action: '$action'"
    ;;
esac
## END INPUT VALIDATION

### EXEC
"$action" "$scratchpad_id" "$target_id" || exit $?
