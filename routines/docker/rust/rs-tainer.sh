#!/bin/sh
# Wrapper around rust container to build binaries from source in isolated environment.
# 
. /usr/lib/helper-func.sh

synopsis(){
    prettySynops=../../pretty-synopsis.pl
    
    SYNOPSIS=$(echo "$(basename $0);;"\
                        "(-r|-c <args to cargo>);;"\
                        " <path>;;Wrapper around rust container to build binaries from source in isolated environment.")
    DESCRIPTION=$(echo "DESCRIPTION;;"\
                        "-r;The -r flag (run) accepts the filepath to the .rs source file which is "\
                        "then compiled and executed in one go.;;"\
                        "-c <cargo args>;The arguments following this flag will be forwarded to cargo during container runtime."\
                        " Cargo will execute the commands inside the defined directory given by <path>.")
    $prettySynops --synopsis="$SYNOPSIS" --description="$DESCRIPTION"
}

verify_args(){
    path="$1"
    c_flag="$2"
    r_flag="$3"

    [ -r "$path" ] || throw "err: either dir/file does not exist or read permission not set."
    [ -n "$c_flag" ] && [ -n "$r_flag" ] throw "err: mutex flags -c and -r detected."
    [ -z "${c_flag}${r_flag}" ] && throw "err: no action indicating flag set."
}

while getopts "rc:" opt; do
    case ${opt} in
        c)
            custom_cmd="$OPTARG"
            ;;
        r)
            compile_run=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            synopsis
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

path=$(realpath "$1" 2>/dev/null) || throw "err: missing path argument."
verify_args "$path" "$custom_cmd" "$compile_run" 

SOURCE_ID=$(basename $path)
SOURCE_DIR=$(dirname $path)

if [ -n "$compile_run" ]; then
    [ -f "$path" ] || throw "err: target ('$SOURCE_ID') to compile and run not a regular file."
    EXEC="rustc $SOURCE_ID" # directly compile and run source
else
    [ -d "$path" ] && SOURCE_DIR="$path"
    EXEC="cargo $custom_cmd" # custom cargo util commands to build, check source, etc.
fi

IMG=rust-build
docker run --rm -v "$SOURCE_DIR:/src" -w /src $IMG "$EXEC"