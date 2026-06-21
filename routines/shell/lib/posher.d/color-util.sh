load_posher core

__ANSI_get_style() {
    _posher_retval=0

    case ${1-} in
      b|bold)         stdout 1;;
      f|faint)        stdout 2;;
      u|underline)    stdout 4;;
      n|normal)       stdout 0;;
      i|italic)       stdout 3;;

      *)
        _posher_retval=$__EXCODE_MISUSED_CMD
        stderr  "invalid font modifier" \
                "$(fmt_assertmsg '{b|f|u|n|i}' "${1-}")"
        ;;
    esac

    return $_posher_retval
}

__ANSI_get_color() {
    _posher_retval=0

    case ${1-} in
      w|white)          stdout 37;;
      r|red)            stdout 31;;
      g|green)          stdout 32;;
      y|yellow)         stdout 33;;
      b|blue)           stdout 34;;
      m|magenta)        stdout 35;;
      c|cyan)           stdout 36;;
      gray)             stdout 90;;
      lr|lightred)      stdout 91;;
      lg|lightgreen)    stdout 92;;
      ly|lightyellow)   stdout 93;;
      lb|lightblue)     stdout 94;;
      lm|lightmagenta)  stdout 95;;
      lc|lightcyan)     stdout 96;;
      black)            stdout 30;;
      tw|truewhite)     stdout 97;;

      *)
        _posher_retval=$__EXCODE_MISUSED_CMD
        stderr  "invalid color option"  \
                "$(fmt_assertmsg 'supported color id' "${1-}")"
        ;;
    esac

    return $_posher_retval
}

__hue_worker() {
    _posher_ansi_color=$(__ANSI_get_color "$2")      \
      && _posher_ansi_style=$(__ANSI_get_style "$3") \
      && printf '\033[%s;%sm%s\033[0m'  \
          "${_posher_ansi_style}"       \
          "${_posher_ansi_color}"       \
          "$1"
}

# what:
#   cosmetically modifies input string according to given params
#
# api:
#   $1: input text (noop on empty string)
#       -> sequence of chars to be colored
#   $2: color id (default: white)
#       -> supported ids located in __ANSI_get_color()
#   $3: font style (default: normal)
#       -> (b)old, (f)aint, (u)nderline, (n)ormal, (i)talic
#
hue() {
    [ -z "${1-}" ] && return 0
    __hue_worker "$1" "${2:-white}" "${3:-normal}"  \
        && _posher_retval=$? || _posher_retval=$?
    unset _fmt_pretty_ansi_color _fmt_pretty_ansi_style
    return $_posher_retval
}
