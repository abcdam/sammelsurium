#!/bin/sh
# Wrapper around rust container to build binaries from source in isolated environment.
# 
. /usr/lib/helper-func.sh

synopsis(){
    prettySynops="$HOME/lib/pretty-synopsis.pl"
    
    SYNOPSIS="$(basename "$0");;\
                        ([ -d <directory> ] <args to cargo> | -r <src filename>);;Wrapper around rust container to build binaries from source in isolated environment."
    DESCRIPTION="DESCRIPTION;;\
                        -r;The -r flag (run) accepts the filepath to the .rs source file which is \
                        then compiled and executed in one go.;;\
                        -c <cargo args>;The arguments following this flag will be forwarded to cargo during container runtime.\
                         Cargo will execute the commands inside the defined directory given by <path>."
    $prettySynops --synopsis="$SYNOPSIS" --description="$DESCRIPTION"
}

verify_args(){
    dir_src="$1"
    cargo_args="$2"
    src_file="$3"

    if [ -n "$src_file" ]; then
        [ -n "$cargo_args" ] && trow "err: rustc does not accept cargo args."
        [ -n "$dir_src" ] && DIR_SRC="$(dirname "$src_file")"
    elif [ -n "$cargo_args" ]; then 
        [ -z "$dir_src" ] && DIR_SRC="$(dirname "$(realpath .)")"
    else throw "err: no cargo args detected."
    fi
}

while getopts "r:d:h" opt; do
    case ${opt} in
        r)
            COMPILE_RUN="$(realpath "$OPTARG")" && [ ! -f "$COMPILE_RUN" ] && throw "err: given filepath to source $COMPILE_RUN is not a regular file"
            ;;
        d)  
            DIR_SRC="$(realpath "$OPTARG")" && [ ! -d "$DIR_SRC" ] && throw "err: given directory option $DIR_SRC does not exist"
            ;;
        h|help) 
            synopsis && exit 0 
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            synopsis
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

[ -n "$DIR_SRC" ] || DIR_SRC="$(pwd -P)"
echo "Selected path: '$DIR_SRC'"
CARGO_ARGS="$@"
verify_args "$DIR_SRC" "$CARGO_ARGS" "$COMPILE_RUN" 
SOURCE_ID=$(basename "$COMPILE_RUN")
if [ -n "$SOURCE_ID" ]; then
    EXEC="/app/rustc-runner.sh $SOURCE_ID" # directly compile and run source
else
    EXEC="cargo $CARGO_ARGS" # custom cargo util commands to build, check source, etc.
fi

IMG=rust-build
#echo "$EXEC $@"
docker run                  \
    -it                     \
    -u "$(id -u):$(id -g)"  \
    --rm                    \
    -v "$DIR_SRC:/src"      \
    -w /src                 \
    --name rs-runner "$IMG" $EXEC
