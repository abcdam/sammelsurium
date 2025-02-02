
is_running_pid() {
    kill -0 "$1" 2>/dev/null
}

get_pid_from_cmd() {
    pgrep -f "$1"
}
