
is_root() {
    [ "$(id --user)" -eq 0 ]
}

verify_root() {
    is_root && return || posher yap throw 'must be root'
}

timestamp() {
    printf '%s' "$(date +"%Y%m%d%H%M")"
}

get_OS_name() {
    # os-release file should exist on most distros
    if [ -f /etc/os-release ]; then
        printf '%s' "$(sed --silent 's/^ID=//p' /etc/os-release)"
    elif [ -f /etc/debian_version ]; then
        printf 'debian'
    elif [ -f /etc/fedora-release ]; then
        printf 'Fedora'
    else
        posher yap throw "OS name not detected, extend get_OS_name()"
    fi
}

get_pkg_gpg_dir() {
    DIR=''
    OSID=$(get_OS_name)

    if      [ "$OSID" = "debian" ]; then DIR=/usr/share/keyrings
    elif    [ "$OSID" = "Fedora" ]; then DIR=/etc/pki/rpm-gpg
    else    posher yap throw "GPG directory for OS '$OSID' not defined, extend get_pkg_gpg_dir()."
    fi
    printf '%s' "$DIR"
}

return_str() { printf '%s' "${1:-}"; }
