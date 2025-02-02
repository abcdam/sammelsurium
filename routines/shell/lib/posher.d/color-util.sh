
_parse_colorify_option() {
    case "$1" in
        ""|n)   printf '0';;
        b)      printf '1';;
        f)      printf '2';;
        i)      printf '3';;
        u)      printf '4';;
        *)      printf '0';;
    esac
}

_parse_colorify_color() {
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
# _input (required): string of chars to be colorified
# _color (default (37) white): supports basic 4-bit color set -> check switch case for keys
# _option (default (n)ormal): (n)ormal, (b)old, (f)aint, (i)talics, (u)nderlined
#
hue() {
    _input="$1"
    [ -z "$_input" ] && printf "Error: missing _input in colorify() arg.\n" >&2 && exit 1
    _color=$(_parse_colorify_color "$2")
    _option=$(_parse_colorify_option "$3")
    RESET=$(printf '\001\033[0m\002')
    printf "\001\033[${_option};${_color}m\002${_input}${RESET}"
}
