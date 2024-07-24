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
