stdout_sep() {
    [ $# -le 1 ] && return 0
    _posher_stdout_sep_old_ifs_state=${IFS+set}
    _posher_stdout_sep_old_ifs_value=${IFS-}
    IFS=$1

    shift && printf '%s' "$*" && _lib_retval=$? || _lib_retval=$?
    [ "${_posher_stdout_sep_old_ifs_state-}" = set ] \
      && IFS=$_posher_stdout_sep_old_ifs_value       \
      || unset IFS
    unset _posher_stdout_sep_old_ifs_state _posher_stdout_sep_old_ifs_value
    return $_lib_retval
}
stderr_sep(){ stdout_sep "$@" >&2 ;}

stdout(){ stdout_sep  ' ' "$@" ;}
stderr(){ stderr_sep  ' ' "$@" ;}

stdoutln_sep(){ stdout_sep    "$@"; printf '\n' ;}
stderrln_sep(){ stdoutln_sep  "$@" >&2          ;}

stdoutln(){ stdoutln_sep ' ' "$@" ;}
stderrln(){ stderrln_sep ' ' "$@" ;}

fmt_assertmsg() { stdout "(expected: $1, got: '${2:-UNDEF}')" ;}
