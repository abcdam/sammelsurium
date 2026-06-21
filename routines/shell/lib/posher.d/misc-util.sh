load_posher core

is_root()   { [ "$(id --user)" -eq 0 ]  ;}
verify_root() { is_root || posher yap throw 'must be root'  ;}

timestamp() { stdout "$(date +"%Y%m%d%H%M")"  ;}


__get_os_worker() {
  _posher_os=$(uname -s) || return $?

  case $_posher_os in
    Darwin) stdout macos || return $? ;;
    Linux)  stdout linux || return $? ;;
    *)
      stderr "unsupported OS '$_posher_os'" || :
      return $__EXCODE_UNSUPPORTED_ENV
      ;;
  esac
}

get_os() {
  __get_os_worker && _lib_retval=$? || _lib_retval=$?
  unset _posher_os
  return $_lib_retval
}

__is_linux_os_worker() {
  _posher_os=${1:-$(get_os)} && [ "$_posher_os" = "linux" ]
}

is_linux_os() {
  __is_linux_os_worker && _lib_retval=$? || _lib_retval=$?
  unset _posher_os
  return $_lib_retval
}

__get_OS_name_worker() {
    is_linux                                          \
      && _posher_os_id=$(sed -n 's/^ID=//p' /etc/os-release) \
      && stdout "$_posher_os_id"
}

get_OS_name() {
    __get_OS_name_worker && _lib_retval=$? || _lib_retval=$?
    unset _posher_os_id
    return $_lib_retval
}

__get_pkg_gpg_dir_worker() {
    _posher_OS_id=$(get_OS_name) || return $?

    case $_posher_OS_id in
      debian) stdout /usr/share/keyrings || return $? ;;
      fedora) stdout /etc/pki/rpm-gpg    || return $? ;;
      *)
        stderr "GPG directory for OS '$_posher_OS_id' not defined, extend get_pkg_gpg_dir()." || :
        return $__EXCODE_UNSUPPORTED_ENV
        ;;
    esac
    return 0
}
get_pkg_gpg_dir() {
    __get_pkg_gpg_dir_worker "$@" && _lib_retval=$? || _lib_retval=$?
    unset _posher_OS_id
    return $_lib_retval
}

return_str() { printf '%s' "${1:-}" ;}
