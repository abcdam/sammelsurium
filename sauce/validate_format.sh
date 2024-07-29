#!/bin/sh

#
# Script to ensure that a .md file or a directory of .md files is grep and awk friendly
#

MULTI_MODE=''
VERBOSE=''
while getopts "vh" opt; do
    case "$opt" in
        v)
            VERBOSE=1
            ;;
        h)
            printf "%s\n" "Usage: $0 [<file>]"
            ;;
        \?)
            printf "unknown option %s\n" "$opt" && exit 1
            ;;
    esac
done
shift $((OPTIND - 1))
TO_CHECK=$1


[ ! "$TO_CHECK" ] && TO_CHECK=$(ls ./*.md) && MULTI_MODE=1

[ $VERBOSE ] && printf "Checking the following docs:\n%s\n" "$TO_CHECK"


[ $MULTI_MODE ] \
    &&  EXPECTED="$(($(ls | wc -l) - 1))" \
        GOT="$(printf "%s\n" "$TO_CHECK" | wc -l)" \
    && [ "$EXPECTED" -ne "$GOT" ] \
    && printf "%s\n" "inconsistent directory structure. Expected #$EXPECTED markdown files and a validator script but got #$GOT files." 1>&2 \
    && exit 1

for path in $TO_CHECK; do
    [ ! -f "$path" ] || [ ! -s "$path" ] \
        && printf "%s\n" "File check failed for '$path'. Either not a regular file or it doesn't exist or its content is empty or some combination of the three." 1>&2 \
        && exit 1
    
    awk -F ';' '
        NF != 4 {
            print "Validation error: Entry must have 4 substrings delimited by a semicolon  - \"" $0 "\""
            exit 1
        }
        $1 !~ /^[a-zA-Z0-9_]+$/ {
            print "Validation error: substring at index 0 contains either whitespace characters or is missing - \"" $1 "\""
            exit 1
        }
        $2 ~ /^[[:space:]]|[[:space:]]$/ || $3 ~ /^[[:space:]]|[[:space:]]$/ {
            print "Validation error: illegal whitespace near semicolons detected - \"" $0 "\""
            exit 1
        }
        $4 !~ /^(https):\/\// {
            print "Validation error: last substring must be a URL - \"" $4 "\""
            exit 1
        }
        {
            split($2, words2, " ")
            split($3, words3, " ")
            if (length(words2) < 1 || length(words3) < 1 || length(words2) > 2) {
                print "Validation error: 2nd and 3rd substrings must contain at least one word and 2nd substring can contain at most 2 words - \"" $2 "\""
                exit 1
            }
        }' "$path"

    if [ $? -ne 0 ]; then printf "File '%s' validation failed. Aborted\n" "$path" 1>2 && exit 1
    elif [ $VERBOSE ]; then printf "is ok: %s\n"  "$path"
    fi
done
