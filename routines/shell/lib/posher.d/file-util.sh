load_posher core

# by default, strips file extension from name.
# if an arbitrary flag is provided as second arg:
#   -> default basename behavior will be used
better_basename() {
  [ -n "${1-}" ] || return 1

  if [ $# -eq 1 ]
    then basename "${1%.*}"
    else basename "$1"
  fi
}

get_dir_of() {
    [ -n "${1-}" ] && dirname "$(abs_path "$1")" \
      && _EX_get_dir_of=$? || _EX_get_dir_of=$?

    [ "$_EX_get_dir_of" -eq 0 ] || stderrln "failed to get dirname of '${1-}'"

    set --    "$_EX_get_dir_of" \
      && unset  _EX_get_dir_of
    return "$1"
}

# TODO: deprecate
is_file() {
    _is_file_path_param=${1-}
    _is_file_canonicalize_param=${2-}
    _EX_is_file=1

    if [ -n "$_is_file_path_param" ] \
    && [ -f "$_is_file_path_param" ]; then
        _EX_is_file=0
        if [ -n "$_is_file_canonicalize_param" ] \
        && ! abs_path "$_is_file_path_param"; then
            _EX_is_file=1
        fi
    fi

    set --    "$_EX_is_file"                \
      && unset  _EX_is_file                 \
                _is_file_path_param         \
                _is_file_canonicalize_param
    return "$1"
}

# TODO: deprecate
is_dir() { [ -d "$(abs_path "$1")" ]  ;}

# variadic path checker.
# Min. two args: the check command in $1 and at least one path
pathtest() {

  [ $# -gt 1 ] || return "$__EXCODE_CMD_MISUSE"

case ${1-} in
  exists)     shift;
              for _ITER in "$@"; do [ -e "$_ITER" ] || return "$__EXCODE"; done
              ;;
  is_file)    shift;
              for _ITER in "$@"; do [ -f "$_ITER" ] || return "$__EXCODE"; done
              ;;
  is_dir)     shift;
              for _ITER in "$@"; do [ -d "$_ITER" ] || return "$__EXCODE"; done
              ;;
  is_link)    shift;
              for _ITER in "$@"; do [ -L "$_ITER" ] || return "$__EXCODE"; done
              ;;
  has_size)   shift;
              for _ITER in "$@"; do [ -s "$_ITER" ] || return "$__EXCODE"; done
              ;;
  can_read)   shift;
              for _ITER in "$@"; do [ -r "$_ITER" ] || return "$__EXCODE"; done
              ;;
  can_write)  shift;
              for _ITER in "$@"; do [ -w "$_ITER" ] || return "$__EXCODE"; done
              ;;
  can_exec)   shift;
              for _ITER in "$@"; do [ -x "$_ITER" ] || return "$__EXCODE"; done
              ;;
  *)
              stderrln "invalid pathtest() command: '${1-}'" || :
              return "$__EXCODE_CMD_MISUSE"
              ;;
esac
  # _ITER is not cleared on error from env for debugging purposes
  # and by its nature, it's an unsafe/unreliable variable anyway
  unset _ITER
}
