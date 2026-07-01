#
# Boring internals
#
readonly __EXCODE=1
readonly __EXCODE_ALREADY_SOURCED=3
readonly __EXCODE_UNSUPPORTED_LIB=5
readonly __EXCODE_NOT_A_FILE=7
readonly __EXCODE_NOT_A_DIR=11
readonly __EXCODE_UNSUPPORTED_ENV=13
readonly __EXCODE_CMD_MISUSE=64
readonly __EXCODE_UNAVAILABLE=69
readonly __EXCODE_IO_RIP=74
readonly __EXCODE_NO_PERM=77
readonly __EXCODE_CMD_NOT_FOUND=127

mkdir -p "$_POSHER_RUNTIME_D"

# TODO: evaluate usefulness and either centralize error code handling here or scrap whole concept
__posher_intern_error_printer() {
  retval=$1
  shift
  case $retval in
    $__EXCODE_UNSUPPORTED_LIB)
        printf "error: lib id '%s' is not whitelisted in get-posher\nset of available libs: %s\n" \
          "$1" "{$(printf "%s|" $_POSHER_LIB_WHITELIST | sed 's/|$//')}" >&2
        ;;
    $__EXCODE_NOT_A_FILE)  printf "error: posher lib '%s' not at expected location '%s'\n" \
          "$@" >&2
        ;;
    *)  printf "error: no error message defined for exit code '%d'\n" "$retval" >&2
        ;;
  esac
  return $retval
}


__posher_intern_is_lib_in_runtime() {
  set -- $__EXCODE 0 "$1"

  _posher_lib_in_rt_ifs_state=${IFS+set}
  _posher_lib_in_rt_ifs_value=${IFS-}
  IFS=":"
  for _ITER in $_POSHER_CTXT_STATE; do
    [ "$_ITER" = "$3" ] \
      && shift && break
  done
  [ "${_posher_lib_in_rt_ifs_state-}" = set ] \
    && IFS="$_posher_lib_in_rt_ifs_value"     \
    || unset IFS

  unset _posher_lib_in_rt_ifs_state  \
        _posher_lib_in_rt_ifs_value
  return $1
}


__posher_intern_validate_lib_loc() {
  set -- "$1" "${POSHER_LIB_DIR}/${1}-util.sh" 0

  _posher_validate_lib_loc_old_ifs_state=${IFS+set}
  _posher_validate_lib_loc_old_ifs_value=${IFS-}
  IFS=" "

  for _ITER in $_POSHER_LIB_WHITELIST; do
    case $_ITER in
      "$1") shift
            ! [ -f "$1" ]                   \
            && set -- $__EXCODE_UNAVAILABLE \
            || printf '%s' "$1"             \
            || set -- $__EXCODE_IO_RIP
            set -- ${2-$1}
            break
          ;;
      *)  ;;
    esac
  done;

  [ "${_posher_validate_lib_loc_old_ifs_state-}" = set ] \
    && IFS=$_posher_validate_lib_loc_old_ifs_value       \
    || unset IFS

  unset _posher_validate_lib_loc_old_ifs_state  \
        _posher_validate_lib_loc_old_ifs_value

  [ $# -eq 1 ] &&  return $1 || return $__EXCODE_UNSUPPORTED_LIB
}


__posher_intern_get_validated_lib_path() {
  retval=0
  location=$(__posher_intern_validate_lib_loc "$1")             \
    && printf '%s' "$location"                                  \
    || __posher_intern_error_printer $? "$1" "${location:-}"    \
    || retval=$? # error printer reflects exit code from prev. cmd
  unset location
  [ $retval -eq 0 ] || exit $retval
}


# $1 -> lib id
__posher_intern_source_if_not_available() {
  __posher_intern_is_lib_in_runtime "$1" \
  || . "$(__posher_intern_get_validated_lib_path "$1")"
}


__posher_intern_run_isolated() (
    retval=0
    __posher_intern_source_if_not_available "$1"
    if ! is_cmd_available "$2"; then
      retval=$__EXCODE_CMD_NOT_FOUND
      printf "error: func '%s' does not exist in lib '%s'\n"    \
        "$2" "$1" >&2 || :
    else
        fun_selector="$2"
        register_sigfile_p "$1" "$fun_selector"
        shift 2
        $fun_selector "$@" && retval=$? || retval=$?
    fi
    exit $retval
)

# *should* be reentrancy-safe
__posher_intern_enable_set_u() {
  case $- in
    *u*)  __POSHER_INTERN_SET_U_LIFO="${__POSHER_INTERN_SET_U_LIFO:-}0"
        ;;
    *)    __POSHER_INTERN_SET_U_LIFO="${__POSHER_INTERN_SET_U_LIFO:-}1"
          set -u
        ;;
  esac
}

# will die if called before __posher_intern_enable_set_u
__posher_intern_restore_set_u() {
  case "${__POSHER_INTERN_SET_U_LIFO:?assertion failed: stack undefined}" in
    *1) set +u ;; *0) : ;;
  esac
  # pop
  __POSHER_INTERN_SET_U_LIFO="${__POSHER_INTERN_SET_U_LIFO%?}"
  [ -z "${__POSHER_INTERN_SET_U_LIFO}" ] && unset __POSHER_INTERN_SET_U_LIFO
  return 0
}


trap 'printf "%s" "$(env)" | sh -c "$_POSHER_EXITRAP"' EXIT
