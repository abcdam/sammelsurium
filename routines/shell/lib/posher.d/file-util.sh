load_posher core

get_basename_no_pfix() { stdout "$(basename "${1%.*}")" ;}

get_dir_of() {
    [ -n "${1-}" ] && dirname "$(abs_path "$1")" \
      && _posher_retval=$? || _posher_retval=$?

    [ "$_posher_retval" -ne 0 ] && stderrln "failed to get dirname of '${1-}'"
    return $_posher_retval
}

# TODO: deprecate
is_file() {
    _is_file_path_param=${1-}
    _is_file_canonicalize_param=${2-}
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

# TODO: deprecate
is_dir() { [ -d "$(abs_path "$1")" ]  ;}

pathtest() (
    retval=0;flag=
    subcmd=${1-}

    case $subcmd in
      exists)    flag="-e" ;;
      is_file)   flag="-f" ;;
      is_dir)    flag="-d" ;;
      is_link)   flag="-L" ;;
      has_size)  flag="-s" ;;
      can_read)  flag="-r" ;;
      can_write) flag="-w" ;;
      can_exec)  flag="-x" ;;
      *)
        retval=$__EXCODE_CMD_MISUSE
        stderrln 'invalid pathtest() command:' "'$subcmd'"
        ;;
    esac

    shift

    if [ "$retval" -eq 0 ]; then
      for _p in "$@"; do
        [ "$flag" "$_p" ] && continue
        retval=1
        stderrln "failed pathtest check '$subcmd' for path '$_p'" || :
        break
      done
    fi

    exit $retval
)
