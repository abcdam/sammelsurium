
# year + month + day + hour + minute + second
# e.g. 20260630023713
timestamp()   { date +%Y%m%d%H%M%S  ;}

get_os() {
  case $(uname -s) in
    Darwin) stdout macos || return $? ;;
    Linux)  stdout linux || return $? ;;
    *)
      eline "unsupported OS, expected Linux or Darwin" || :
      return "$__EXCODE_UNSUPPORTED_ENV"
      ;;
  esac
}


is_linux() { [ "${1:-$(get_os)}" = linux ] ;}

get_OS_name(){ is_linux && sed -n 's/^ID=//p' /etc/os-release ;}


get_pkg_gpg_dir() {
  _EX_get_pkg_gpg_dir_=0
  _posher_OS_id=$(get_OS_name) || _EX_get_pkg_gpg_dir_=$?
  set -- "$_posher_OS_id" $_EX_get_pkg_gpg_dir_
  unset _posher_OS_id _EX_get_pkg_gpg_dir_
  [ $2 -eq 0 ] || return $2
  case $1 in
    debian) stdout /usr/share/keyrings || return $? ;;
    fedora) stdout /etc/pki/rpm-gpg    || return $? ;;
    *)
      eline "GPG directory for OS '$1' not defined, extend get_pkg_gpg_dir()." || :
      return $__EXCODE_UNSUPPORTED_ENV
      ;;
  esac
  return $2
}

return_str() { printf '%s' "${1:-}" ;}
