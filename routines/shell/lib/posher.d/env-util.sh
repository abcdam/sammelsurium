
is_root()     { [ $(id -u) -eq 0 ]  ;}

assert_root() { is_root || throw 'must be root' $__EXCODE_NO_PERM ;}


# what:
#   Variadic idempotent PATH prepender. Takes a list of absolute paths and prepends
#     them in LIFO order => Prio(item i) > Prio(item i+1) > ... > Prio($PATH).
#       Given an arglist of valid, not-yet-seen paths:
#       - "/usr/local/bin" "/home/bob/bin" "/home/bob/.local/bin"
#       The new PATH will be:
#       - "/usr/local/bin:/home/bob/bin:/home/bob/.local/bin:$PATH"
#       If PATH already includes "/home/bob/bin", the new PATH will be:
#       - "/usr/local/bin:/home/bob/.local/bin:$PATH"
#       The arglist order is preserved and entries are deduplicated
#         against the input + already existing $PATH items.
#         Commitment is atomic. The operation aborts on first error.
# api:
#   $@: list of search paths
#       - exit code 0:  PATH includes all deduplicated input paths
#       - exit code 1:  either a relative, `/`, or empty item encountered
#       - exit code 11: one of the items is not a directory
#
prepend_PATH() {
    [ -n "${1-}" ] || return $__EXCODE

    __prepend_PATH_worker "$@" || _EX_prepend_PATH=$?

    set -- ${_EX_prepend_PATH-0} "${_posher_sanitized:-0}"
    unset _EX_prepend_PATH _posher_sanitized

    [ $1 -eq 0 ] && ! [ $2 -eq 0 ] || return $1
    export PATH="$2${PATH:+:$PATH}"
}

__prepend_PATH_worker() {
    _posher_sanitized=''
    for _ITER; do
      case $_ITER in
        /*) _ITER=${_ITER%%"${_ITER##*[!/]}"} ;;
        *)  return $__EXCODE                  ;;
      esac
      # reject root path
      [ -n "$_ITER" ] && [ "$_ITER" != '/' ] || return $__EXCODE
      [ -d "$_ITER" ] || return $__EXCODE_NOT_A_DIR

      case ":$_posher_sanitized:\n:$PATH:" in
        *":$_ITER:"*) ;;
        *) _posher_sanitized="${_posher_sanitized}${_posher_sanitized:+:}$_ITER" ;;
      esac
    done
    unset _ITER
}
