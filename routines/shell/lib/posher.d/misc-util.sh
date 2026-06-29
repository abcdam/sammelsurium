load_posher core



# year + month + day + hour + minute + second
# e.g. 20260630023713
timestamp()   { stdout $(date +%Y%m%d%H%M%S)  ;}

get_os() {
  case $(uname -s) in
    Darwin) stdout macos || return $? ;;
    Linux)  stdout linux || return $? ;;
    *)
      stderr "unsupported OS, expected Linux or Darwin" || :
      return "$__EXCODE_UNSUPPORTED_ENV"
      ;;
  esac
}


is_linux() { [ "${1:-$(get_os)}" = linux ] ;}

get_OS_name(){ is_linux && sed -n 's/^ID=//p' /etc/os-release ;}

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
    __get_pkg_gpg_dir_worker "$@" \
      && _EX_get_pkg_gpg_dir=$? || _EX_get_pkg_gpg_dir=$?

    set --    "$_EX_get_pkg_gpg_dir" \
      && unset  _EX_get_pkg_gpg_dir  \
                _posher_OS_id
    return "$1"
}

return_str() { printf '%s' "${1:-}" ;}
