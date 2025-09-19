get_basename_no_pfix() {
    printf '%s' "$(basename "${1%.*}")"
}

get_dir_of() {
    [ -n "$1" ] && dirname "$(abs_path "$1")" && return     \
        || posher yap throw 'received empty directory path'
}

is_file() {
    _is_file_path_param="${1:-}"
    _is_file_canonicalize_param="${2:-}"
    retval=1

    if [ -n "$_is_file_path_param" ] \
    && [ -f "$_is_file_path_param" ]; then
        retval=0
        if [ -n "$_is_file_canonicalize_param" ] \
        && ! abs_path "$_is_file_path_param"; then
            retval=1
        fi
    fi

    unset _is_file_path_param _is_file_canonicalize_param
    return $retval
}

is_dir() {
    [ -d "$(abs_path "$1")" ]
}
