load_posher color

# simple newline print with optional prefix tag
ramble() {
    prefix="${2:-}"
    [ -n "$prefix" ] && prefix="$prefix "
    printf "%s%s\n" "$prefix" "$1"
}

# sneak in relevant info after execution step resolved
_statusline_addendum() {
    [ -n "$1" ] && adum="$(hue " $1" gray)" || adum=''
    ramble "$adum"
}

_whitespace_pad() {
    max_len=$2
    [ -z "$max_len" ] && throw '_whitespace_pad() requires max length as second arg'
    txt="$1"
    chars_no=${#txt}
    left_pad=$(( (max_len - chars_no) / 2 ))
    right_pad=$(( max_len - chars_no - left_pad ))
    printf '%*s%s%*s' "$left_pad" '' "$txt" "$right_pad" ''
}

_set_status_outcome() {
    printf "[%s]" "$(hue "$(_whitespace_pad "$1" 4)" "$2" 'b')"
    _statusline_addendum "$3"
}

status_ok()     { _set_status_outcome 'FINE'    'lg'    "$1"; }
status_warn()   { _set_status_outcome 'WARN'    'y'     "$1"; }
status_fail()   { _set_status_outcome 'FAIL'    'r'     "$1"; }
status_info()   { _set_status_outcome 'INFO'    'lb'    "$1"; }

# wraps step execution with the corresponding outcome indicators
# generated by status_ok, status_warn, and status_fail. Makes it easy to
# expose helpful information to the user during sequential multistep logic
statusline() {
    no_indent="${2:-}"
    [ -z "$no_indent" ]     \
        && txt=" - $1"      \
        || txt="$1"

    len="${#txt}"
    # default terminal with 80 columns, 6 chars reserved for outcome status
    dots=$((74 - len))
    pad=''
    if [ "$dots" -gt 0 ]; then
        pad="$(printf "%0${dots}d" 0 | tr 0 '.')"
    fi
    printf "%s%s" "$txt" "$pad"
}

# shortcut for a state independent `statusline && status_info`. Useful for state transitions
infoline() {
    statusline     "$1" "indent_off"
    status_info     "$2"
}

throw() {
    ramble "$(hue "[FATAL] $1" r b)" >&2
    exit $(( ${2-1} )) ## Exit code at $2, or 1 by default
}

# general purpose printers
_shared_rambling_fmt() { ramble "$1" "[$(hue "$2" "$3")]"; }

yell()  { _shared_rambling_fmt "$1" 'crit' 'r';  }
bless() { _shared_rambling_fmt "$1" 'succ' 'lg'; }
hint()  { _shared_rambling_fmt "$1" 'hint' 'ly'; }
tell()  { _shared_rambling_fmt "$1" 'info' 'w';  }
