__stdout_sep_worker() {
    __old_ifs="$IFS"
    IFS="$1"
    shift && printf '%s' "$*"
    IFS="$__old_ifs"
}
stdout_sep() {
    [ $# -eq 0 ] && return 0
    __stdout_sep_worker "$@" && _lib_retval=$? || _lib_retval=$?
    unset __old_ifs
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
