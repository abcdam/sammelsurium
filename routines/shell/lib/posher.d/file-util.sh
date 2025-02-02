get_basename_no_pfix() {
    printf '%s' "$(basename "${1%.*}")"
}

get_dir_of() {
    [ -n "$1" ] && dirname "$(abs_path "$1")" && return     \
        || . $(posher)  throw 'received empty directory path'
}

is_file() {
    [ -f "$(abs_path "$1")" ]
}

is_dir() {
    [ -d "$(abs_path "$1")" ]
}
