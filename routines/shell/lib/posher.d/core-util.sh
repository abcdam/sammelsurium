stdout_sep() {
    [ $# -gt 1 ] || return 0
    _stdout_sep_ifs_state=${IFS+set}
    _stdout_sep_ifs_value=${IFS-}
    IFS=$1

    shift && printf '%s' "$*" && _EX_stdout_sep=$? || _EX_stdout_sep=$?
    [ "${_stdout_sep_ifs_state-}" = set ] \
      && IFS=$_stdout_sep_ifs_value       \
      || unset IFS

    set --    "$_EX_stdout_sep"           \
      && unset  _EX_stdout_sep            \
                _lib_stdout_sep_ifs_state \
                _stdout_sep_ifs_value
    return "$1"
}
stderr_sep(){ stdout_sep "$@" >&2 ;}

stdout(){ stdout_sep  ' ' "$@" ;}
stderr(){ stderr_sep  ' ' "$@" ;}

stdoutln_sep(){ stdout_sep    "$@"; printf '\n' ;}
stderrln_sep(){ stdoutln_sep  "$@" >&2          ;}

stdoutln(){ stdoutln_sep ' ' "$@" ;}
stderrln(){ stderrln_sep ' ' "$@" ;}

fmt_assertmsg() { stdout "(expected: $1, got: '${2:-UNDEF}')" ;}
