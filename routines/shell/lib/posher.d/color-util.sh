load_posher core

readonly __ANSI_ESCAPE_CHAR=$(printf '\033')



__ANSI_get_style() {
    case ${1-} in
      b|bold)         stdout 1;;
      f|faint)        stdout 2;;
      u|underline)    stdout 4;;
      n|normal)       stdout 0;;
      i|italic)       stdout 3;;

      *)
        stderr  "invalid font modifier" \
                "$(fmt_assertmsg '{b|f|u|n|i}' "${1-}")" || :
        return $__EXCODE_CMD_MISUSE
        ;;
    esac
}

__ANSI_get_color() {
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
        stderr  "invalid color option"  \
                "$(fmt_assertmsg 'supported color id' "${1-}")" || :
        return $__EXCODE_CMD_MISUSE
        ;;
    esac
}

__hue_worker() {
    _posher_ansi_color=$(__ANSI_get_color "$2")      \
      && _posher_ansi_style=$(__ANSI_get_style "$3") \
      && printf '%b[%d;%dm%s%b[0m'  \
          "${__ANSI_ESCAPE_CHAR}"   \
          "${_posher_ansi_style}"   \
          "${_posher_ansi_color}"   \
          "$1"                      \
          "${__ANSI_ESCAPE_CHAR}"   \
      && _hue_worker_ec=$?          \
      || _hue_worker_ec=$?

  set --    "$_hue_worker_ec"     \
    && unset  _hue_worker_ec      \
              _posher_ansi_color  \
              _posher_ansi_style
    return "$1"
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
    [ -n "${1-}" ] || return 0

    if [ "${NO_COLOR+set}" = set ]
        then __hue_worker "$1" "${2:-white}" "${3:-normal}"
        else stdout "$1"
    fi
}

# what:
#   strips ansi control sequences from input text.
#   covers graphical color/style mode
#
# api:
#   $1: input string
ansi_stripper() {
  [ -n "${1-}" ] || return 0
    while :; do case $1 in
        *"${__ANSI_ESCAPE_CHAR}["*m*)
          _posher_pref=${1%%"$__ANSI_ESCAPE_CHAR"*}
          _posher_rest=${1#*"${__ANSI_ESCAPE_CHAR}["}
          set -- "$_posher_pref${_posher_rest#*m}"
                  ;;
        *) break  ;;
      esac;
    done
    unset _posher_pref _posher_rest
    stdoutln "$1"
}
