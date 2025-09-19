

_parse_ANSI_style() {
    ANSI_style_id="${1:-}"; retval=0
    is_param_set "$ANSI_style_id" || retval=$?

    if [ $retval -ne 0 ]; then
        fmt="$__POSHER_ERR_MSG_PREFIX _parse_ANSI_style(): requires param to be set"
        printf "$fmt\n" >&2
    else
        case "$ANSI_style_id" in
            n|normal)       printf '0';;
            b|bold)         printf '1';;
            f|faint)        printf '2';;
            i|italic)       printf '3';;
            u|underline)    printf '4';;
            *) retval=64
        fmt="$__POSHER_ERR_MSG_PREFIX: %s. (expected: one of '%s' - got: '%s')"
                printf "$fmt\n"                                 \
                    "_parse_ANSI_style(): invalid font modifier"   \
                    "bfuni"                                     \
                    "$ANSI_style_id" >&2
                ;;
        esac
    fi
    unset ANSI_style_id fmt
    return $retval
}

_parse_ANSI_color() {
    ANSI_color_id="${1:-}"; retval=0
    is_param_set "$ANSI_color_id" || retval=$?

    if [ $retval -ne 0 ]; then
        fmt="$__POSHER_ERR_MSG_PREFIX _parse_ANSI_color(): requires param to be set"
        printf "$fmt\n" >&2
    else
        case "$ANSI_color_id" in
            w|white)                printf '37';;
            r|red)                  printf '31';;
            g|green)                printf '32';;
            y|yellow)               printf '33';;
            b|blue)                 printf '34';;
            m|magenta|p|purple)     printf '35';;
            c|cyan)                 printf '36';;
            gray)                   printf '90';;
            lr|lightred )           printf '91';;
            lg|lightgreen)          printf '92';;
            ly|lightyellow)         printf '93';;
            lb|lightblue)           printf '94';;
            lm|lightmagenta|lp|lightpurple) printf '95';;
            lc|lightcyan)           printf '96';;
            black)                  printf '30';;
            tw|truewhite)           printf '97';;
            *)  retval=64
        fmt="$__POSHER_ERR_MSG_PREFIX: %s. (expected: valid 4-bit color key - got: '%s')"
                printf "$fmt\n"                                 \
                    "_parse_ANSI_color(): invalid color option" \
                    "$ANSI_color_id" >&2
                ;;
        esac
    fi
    unset ANSI_color_id fmt
    return $retval
}

# Output: cosmetically modified input string according to given params
# $input_txt:
#       sequence of chars to be colored
# $with_color (defaults to white):
#       supports basic 4-bit color set by id -> check switch case for keys
# $with_style (defaults to (n)ormal):
#       (n)ormal, (b)old, (f)aint, (i)talic, (u)nderline
#
hue() {
    input_txt="${1:-}"
    with_color="${2:-white}"
    with_style="${3:-normal}"
    retval=0
    is_param_set "$input_txt" || retval=$?
    if [ $retval -eq 0 ]; then
      ansi_color="$(_parse_ANSI_color "$with_color")"       \
        && ansi_style="$(_parse_ANSI_style "$with_style")"  \
        || retval=$?

      if [ $retval -eq 0 ]; then
        RESET='\033[0m'
        printf "\033[${ansi_style};${ansi_color}m${input_txt}${RESET}"
      fi
    else
      fmt="$__POSHER_ERR_MSG_PREFIX hue(): requires input_txt param to be set"
      printf "$fmt\n" >&2
    fi

    unset input_txt ansi_color ansi_style with_color with_style
    return $retval
}
