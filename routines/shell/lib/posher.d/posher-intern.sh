#
# Boring internals
#
__EXCODE_GENERAL=1
__EXCODE_ALREADY_SOURCED=3
__EXCODE_UNSUPPORTED_LIB=5
__EXCODE_NOT_A_FILE=7
__EXCODE_NOT_A_DIR=11
__EXCODE_UNSUPPORTED_ENV=13
__EXCODE_MISUSED_CMD=64

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


__posher_intern_confirm_lib_not_in_runtime() {
  retval=0
  if  [ -n "$_POSHER_CTXT_STATE" ]; then
    IFS=":"
    for loaded_lib in $_POSHER_CTXT_STATE; do
      [ "$loaded_lib" = "$1" ] \
        && retval=$__EXCODE_ALREADY_SOURCED && break
    done
  fi
  unset IFS loaded_lib
  return $retval
}


__posher_intern_validate_lib_loc() {
  retval=$__EXCODE_UNSUPPORTED_LIB
  lib_path="${POSHER_LIB_DIR}/${1}-util.sh"
  IFS=" "

  for existing_lib in $_POSHER_LIB_WHITELIST; do
    if [ "$existing_lib" = "$1" ]; then
      [ -f "$lib_path" ] && retval=0 || retval=$__EXCODE_NOT_A_FILE
      printf '%s' "$lib_path"
      break
    fi
  done; unset IFS existing_lib lib_path

  return $retval
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
  __posher_intern_confirm_lib_not_in_runtime "$1" \
  && . "$(__posher_intern_get_validated_lib_path "$1")"
}


__posher_intern_run_isolated() {
  (
    retval=0
    if __posher_intern_source_if_not_available "$1"  \
      && is_cmd_available "$2"; then
        fun_selector="$2"
        register_sigfile_p "$1" "$fun_selector"
        shift 2
        $fun_selector "$@" || retval=$?
        return $retval
    fi
    if __posher_intern_confirm_lib_not_in_runtime "$1" || retval=$?; then
      printf "error: failed to load lib '%s' for func '%s'\n"   \
        "$1" "$2" >&2
    else
      retval=$?
      printf "error: func '%s' does not exist in lib '%s'\n"    \
        "$2" "$1" >&2
    fi
    exit $retval
  )
}

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
