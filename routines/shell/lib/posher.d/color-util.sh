
_parse_hue_opt() {
    case "$1" in
        ""|n)   printf '0';;
        b)      printf '1';;
        f)      printf '2';;
        i)      printf '3';;
        u)      printf '4';;
        *)      printf '0';;
    esac
}

_parse_hue_color() {
    case "$1" in
        ""|w|white)             printf '37';;
        r|red)                  printf '31';;
        g|green)                printf '32';;
        y|yellow)               printf '33';;
        b|blue)                 printf '34';;
        m|magenta|p|purple)     printf '35';;
        c|cyan|t|turquoise)     printf '36';;
        gray)                   printf '90';;
        lr|lightred|lred)       printf '91';;
        lg|lightgreen|lgreen)   printf '92';;
        ly|lightyellow|lyellow) printf '93';;
        lb|lightblue|lblue)     printf '94';;
        lm|lightmagenta|lmagenta|lp|lpurple|lightpurple) printf '95';;
        lc|lightcyan|lcyan|lt|lturquoise|lightturquoise) printf '96';;
        black)                  printf '30';;
        tw|twhite|truewhite)    printf '97';;
        *)                      printf '37';;
    esac
}

# Output: cosmetically modified input string according to given params
# $1: txt (required): string of chars to be colored
# _color (default (37) white): supports basic 4-bit color set -> check switch case for keys
# _option (default (n)ormal): (n)ormal, (b)old, (f)aint, (i)talics, (u)nderlined
#
hue() {
    [ -z "$1" ] && printf "Error: missing 1st positional argument (target text) in hue() params .\n" >&2 && exit 1
    _hue_color="$(_parse_hue_color "${2:-}")"
    _hue_opt="$(_parse_hue_opt "${3:-}")"
    RESET='\033[0m'
    printf "\033[${_hue_opt};${_hue_color}m${1}${RESET}"
}
