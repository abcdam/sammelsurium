

_parse_ANSI_style_opt() {
    ANSI_style_opt=${1:-}
    is_param_set "$ANSI_style_opt" && retval=$? || retval=$?

    if [ $retval -ne 0 ]; then
        fmt="$__POSHER_ERR_MSG_PREFIX _parse_hue_opt(): requires param to be set"
        printf "$fmt\n" >&2
    else
        case "$ANSI_style_opt" in
            n|normal)       printf '0';;
            b|bold)         printf '1';;
            f|faint)        printf '2';;
            i|italic)       printf '3';;
            u|underline)    printf '4';;
            *) retval=64
        fmt="$__POSHER_ERR_MSG_PREFIX: %s. (expected: one of '%s' - got: '%s')"
                printf "$fmt\n"                                 \
                    "_parse_hue_opt(): invalid font modifier"   \
                    "bfuni"                                     \
                    "$ANSI_style_opt" >&2
                ;;
        esac
    fi
    unset ANSI_style_opt fmt
    return $retval
}

_parse_ANSI_color() {
    ANSI_color_opt=${1:-}
    is_param_set "$ANSI_color_opt" && retval=$? || retval=$?

    if [ $retval -ne 0 ]; then
        fmt="$__POSHER_ERR_MSG_PREFIX _parse_ANSI_color(): requires param to be set"
        printf "$fmt\n" >&2
    else
        case "$ANSI_color_opt" in
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
                    "$ANSI_color_opt" >&2
                ;;
        esac
    fi
    unset ANSI_color_opt fmt
    return $retval
}

# Output: cosmetically modified input string according to given params
# $1: txt (required): string of chars to be colored
# $2: _color (default (37) white): supports basic 4-bit color set -> check switch case for keys
# $3: _option (default (n)ormal): (n)ormal, (b)old, (f)aint, (i)talic, (u)nderline
#
hue() {
    [ -z "$1" ] && printf "Error: missing 1st positional argument (target text) in hue() params.\n" >&2 && exit 1
    _hue_color="$(_parse_ANSI_color "${2:-}")"
    _hue_opt="$(_parse_ANSI_style_opt "${3:-}")"
    RESET='\033[0m'
    printf "\033[${_hue_opt};${_hue_color}m${1}${RESET}"
}
