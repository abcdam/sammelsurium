#!/bin/sh
# Wrapper around rust container to build binaries from source in isolated environment.
#   Builds and runs binary with -r -p <path-to-src.rs>
#   Alternatively, execute cargo cmds when input is formed according to 
#       the pattern '-c <ARGS> -p <PATH-2-MOUNT>'
. /usr/lib/helper-func.sh

while getopts ":r:c:p:" opt; do
    case ${opt} in
        c)
            custom_cmd="$OPTARG"
            ;;
        p)
            path="$OPTARG"
            ;;
        r)
            RUN=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

[ -n "$path" ] && [ ! -f "$path" ] && [ ! -d "$path" ] && throw "err: given path '$path' not a directory and not a file"
[ -n "$BUILD" ] && [ -n "$custom_cmd" ] && throw "err: mutex flags -b and -c detected"

SOURCE_ID=$(basename $path)

[ ! -d $SOURCE_ID ] && SOURCE_DIR=$(dirname $SOURCE_ID) || SOURCE_DIR=$SOURCE_ID

if [ -n "$RUN" ]; then
    EXEC="rustc $SOURCE_ID" # directly compile and run source
elif [ -n "$custom_cmd" ]; then 
    EXEC="cargo $custom_cmd" # custom cargo util commands to build, check source, etc.
else throw "err: no actionable command detected."
fi

IMG=rust-build
docker run --rm -v "$SOURCE_DIR:/src" $IMG "$EXEC" "$@"