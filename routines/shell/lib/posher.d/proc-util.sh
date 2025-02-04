is_running_pid()   { kill -0 "${1:-}" 2>/dev/null; }

pgrep_cmd_strict() {
    cmd2match="${1:-}"
    ps -e -o pid= -o command= | awk -v full_cmd="$cmd2match" '{
        pid = $1
        sub(/^[[:space:]]*[0-9]+[[:space:]]*/, "", $0) # sanitize line
        if ($0 == full_cmd) print pid
    }'
}
