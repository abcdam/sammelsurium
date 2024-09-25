#!/bin/dash

#
# a hopefully posix compliant helper library
# http://gondor.apana.org.au/~herbert/dash
# https://pubs.opengroup.org/onlinepubs/007904875/utilities/xcu_chap01.html#tag_01


_print() {
    printf '%s' "$1" 
}

is_root() {
    [ "$(id --user)" -eq 0 ]
}

verify_root() {
    is_root || throw 'must be root'
}

throw() {
    printf "%s\n" "$1" >&2 
    exit "${2-1}" ## Return code at $2, or 1 by default
}

get_OS_name() {
    # os-release file should exist on most distros
    OSID=$(sed --silent 's/^ID=//p' /etc/os-release) && [ -n "$OSID" ] && _print "$OSID" && return
    [ -f /etc/debian_version ] && _print "debian" && return
    [ -f /etc/fedora-release ] && _print "Fedora" && return

    throw "OS name not detected, extend get_OS_name()."

}

get_pkg_gpg_dir() {
    DIR=''
    OSID=$(get_OS_name)
    
    if      [ "$OSID" = "debian" ]; then DIR=/usr/share/keyrings
    elif    [ "$OSID" = "Fedora" ]; then DIR=/etc/pki/rpm-gpg
    else    throw "GPG directory for OS '$OSID' not defined, extend get_pkg_gpg_dir()."
    fi
    _print "$DIR" && return
}

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
        ""|w|white)         printf '37';;
        r|red)              printf '31';;
        g|green)            printf '32';;
        y|yellow)           printf '33';;
        b|blue)             printf '34';;
        m|magenta|p|purple) printf '35';;
        c|cyan|t|turquoise) printf '36';;
        gray)               printf '90';;
        lr|lightred|lred)   printf '91';;
        lg|lightgreen|lgreen)   printf '92';;
        ly|lightyellow|lyellow) printf '93';;
        lb|lightblue|lblue)     printf '94';;
        lm|lightmagenta|lmagenta|lp|lpurple|lightpurple) printf '95';;
        lc|lightcyan|lcyan|lt|lturquoise|lightturquoise) printf '96';;
        black)              printf '30';;
        tw|twhite|truewhite)    printf '97';;
        *)                  printf '37';;
    esac
}

# Output: cosmetically modified input string according to given params
# _input (required): string of chars to be colorified
# _color (default (37) white): supports basic 4-bit color set -> check switch case for keys
# _option (default (n)ormal): (n)ormal, (b)old, (f)aint, (i)talics, (u)nderlined
#
colorify() {
    _input="$1"
    [ -n "$_input" ] || throw "Error: no _input given."
    _color=$(_parse_colorify_color "$2")
    _option=$(_parse_colorify_option "$3")
    RESET=$(printf '\001\033[0m\002')
    printf "\001\033[${_option};${_color}m\002${_input}${RESET}"
}
