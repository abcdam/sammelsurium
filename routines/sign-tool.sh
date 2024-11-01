#!/bin/sh

# 2024 @abcdam
# sign-tool: A utility for signing and verifying files using GPG

. /usr/lib/helper-func.sh

synopsis(){
    excode=$1
    prettySynops="$(get_dir_of $0)/pretty-synopsis.pl"
    SYNOPSIS="$(basename $0);;\
                [-dh];;\
                [--identity <key_uid>];;\
                {--sign <target> <o_dir> | --verify <target> <signature>};;\
                sign-tool: A utility for signing and verifying files using GPG"
    DESCRIPTION="ARGUMENTS;;\
            -i;--identity <key_id>;Specify the key ID to use to sign the target;;\
            -s;--sign <target> <o_dir>;Sign the target file and write the signature to the output directory;;\
            -v;--verify <target> <signature>;Verify the signature of the file at target path;;\
            -d;--debug;Enable debug mode;;\
            -h;--help;Show this help text and exit"
    $prettySynops --synopsis="$SYNOPSIS" --description="$DESCRIPTION"
    exit $excode
}

while getopts "i:s:v:dh" opt; do
    case ${opt} in
        i|identity )
            key_id="$OPTARG" && gpg -k $key_id 2>&1 >/dev/null || throw "err: owner of $key_id not in your keychain yet, import their pubkey first."
            ;;
        s|sign )
            target_to_sign=$(realpath "$OPTARG") && [ ! -f "$target_to_sign" ] && throw "err: file '$target_to_sign' to be signed not a regular file."
            ;;
        v|verify )
            verify_target=$(realpath "$OPTARG") && [ ! -f "$verify_target" ] && throw "err: file '$verify_target' to be verified not a regular file."
            ;;
        h|help )
            synopsis 0
            ;;
        d|debug )
            debug_mode=1
            ;;
        \? )
            synopsis 1
            ;;
    esac
done

shift $((OPTIND -1))
path=$(realpath "$1" 2>/dev/null)  || throw "err: missing path argument."

[ -n "$target_to_sign" ] && [ -n "$verify_target" ] && throw "err: mutex flags --sign and --verify detected."
[ -z "${target_to_sign}${verify_target}" ] && throw "err: no action specified."

if [ -n "$target_to_sign" ]; then
    [ -z "$key_id" ] && throw "err: key id not set with -i flag."
    [ -d "$path" ] || throw "err: given signature output directory '$path' not a directory."
    gpg -au $key_id -o "$path/$(basename $target_to_sign).asc" --detach-sig $target_to_sign || throw "err: creating signature failed."
else
    [ -f "$path" ] || throw "err: path '$path' not a regular file. Is it really the signature file of '$verify_target'?"
    output="$(gpg --verify "$path" "$verify_target" 2>&1)" || throw "err: $output"
    [ -n "$debug_mode" ] && print_ok "$output"
fi


