#!/bin/sh
. /etc/shinit



if [ -t 0 ] && [ "$1" = "/bin/dash" ]; then
  parrot(){ printf '%*s' "$1" '' | tr ' ' "${2-\\\\}" ;}
  intro_width=40
  mid_lead='\\  Welcome back  '
  mid_trail="  $(id -un)  \\\\"
  printf '%s\n%s\n%s%s%s\n%s\n%s\n\n'                             \
    "$(parrot $(( intro_width - 2 )) '_')"                        \
    "$(parrot $(( intro_width - 1 )))"                            \
    "$mid_lead"                                                   \
    "$(parrot $(( intro_width - ${#mid_lead} - ${#mid_trail} )))" \
    "$mid_trail"                                                  \
    "$(parrot $intro_width '/')"                                  \
    "$(parrot $(( intro_width - 1 )) '*')"
fi
exec "$@"
