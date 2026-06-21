load_posher core

__prepend_PATH_worker() {
    _posher_sanitized=''
    for _posher_p; do
      case $_posher_p in
        /*) _posher_p=${_posher_p%%"${_posher_p##*[!/]}"} ;;
        *)  return $__EXCODE_GENERAL                      ;;
      esac
      # reject root path
      [ -n "$_posher_p" ] || return $__EXCODE_GENERAL
      [ -d "$_posher_p" ] || return $__EXCODE_NOT_A_DIR

      case ":$_posher_sanitized:\n:$PATH:" in
        *":$_posher_p:"*) ;;
        *) _posher_sanitized="${_posher_sanitized}${_posher_sanitized:+:}$_posher_p" ;;
      esac
    done
}

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
    [ -n "${1-}" ] || return $__EXCODE_GENERAL

    __prepend_PATH_worker "$@" && _posher_retval=$? || _posher_retval=$?

    [ "$_posher_retval" -eq 0 ]                             \
      && [ -n "$_posher_sanitized" ]                        \
      && export PATH="${_posher_sanitized}${PATH:+:$PATH}"  \
      || :

    unset _posher_p _posher_sanitized
    return $_posher_retval
}
