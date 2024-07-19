is_root() {
    if [ "$EUID" -eq 0 ]; then
        return 0  # true
    fi
    return 1  # false
}

function throw {
    printf '%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

function file_exists {
  if [ -f "$1" ]; then
      return 0
  fi
  return 1
}