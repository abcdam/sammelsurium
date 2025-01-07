#!/bin/dash
# Simple event loop that can run as a daemon upon user login to execute long-running 'KDE Activity' specific tasks.
# Can be easily extended to cover new activities by writing a `run_<activity_name>_tasks` routine and 
#   registering the activity in the `is_activity_implemented()` function.
# More complex activites can be placed in ./tasks dir.
set -e

trap 'state_reset' TERM INT

. /usr/lib/helper-func.sh

KDE_APP_BUS='qdbus org.kde.ActivityManager'
API_ACTIVITY='/ActivityManager/Activities'
API_NS='org.kde.ActivityManager.Activities'
QUERY="$KDE_APP_BUS $API_ACTIVITY $API_NS"
GET_CURRENT_ACTIVITY="$QUERY.CurrentActivity"
GET_ACTIVITY_NAME="$QUERY.ActivityName"

SCRIPT_ID="$(get_basename_no_pfix "$0")"
PID_DIR="/run/user/$(id -u)/$SCRIPT_ID"
INSTANCE_PREFIX="$(get_timestamp)"
TASKS_DIR=$(realpath ./tasks)
last_activity=""
first_run=1 # toggle to filter out events at the start



##
# worker tasks
##
run_DEV_tasks() {
    pidfile="$1"
    cmd="$TASKS_DIR/i3.task"
    dispatch "$cmd" "$pidfile"
}

run_CASUAL_tasks() {
    pidfile="$1"
    cmd='konsole --hold -e "/bin/bash g2git"'
    dispatch "$cmd" "$pidfile"
}

dispatch() {
    cmd="$1"
    pidfile="$2"
    /bin/sh -c "$cmd" &
    pid=$!
    echo "$pid" > "$pidfile"
}

##
# helper
##
is_activity_implemented() {
    echo "$1" | grep -qE 'DEV|CASUAL'                                   && 
        return 0
    warn_ok "info: worker function 'run_${1}_tasks()' not implemented"  && 
        return 1
}

is_ready_to_run_tasks() {
    local activity_name="$1"
    is_activity_implemented "$activity_name"    &&
        pidfile="$2"                            &&
        ! is_file "$pidfile"
}

get_name() {
    local id="$1"
    printf '%s' "$($GET_ACTIVITY_NAME "$id")"
}

is_valid_pidfile() {
    _pidf="$1"
    [ "$(cat "$_pidf" | wc -l)" -eq 1 ]
}

cleanup() {
    for pidfile in $PID_DIR/*; do
        pid="$(cat "$pidfile")" 
        if is_valid_pidfile "$pidfile"; then
            if is_running "$pid"; then
                kill "$pid" || kill -9 "$pid"
            fi
            rm "$pidfile"
        else 
            warn_ok "ERR: Cleanup of process '$pid' skipped. Reason: malformed pid file '$pidfile'. Please check & delete it manually."
        fi
    done
}

is_valid_prerun_state() {
    mkdir -p "$PID_DIR"
    [ -z "$(ls "$PID_DIR")" ] 
}

##
# main
##
state_reset() {
    if ! [ -d "$PID_DIR" ] || [ -z "$(ls "$PID_DIR")" ]; then 
        echo "warn: pid dir empty, nothing to clean up" 
        return 0
    fi
    cleanup
}

run_event_loop() {
    is_valid_prerun_state || throw "ERR: cannot run with dirty state. Pid dir $PID_DIR must be empty."
    dbus-monitor --session "type='signal',interface='org.kde.ActivityManager.Activities',member='CurrentActivityChanged'" | while read line; do
        current_activity="$($GET_CURRENT_ACTIVITY)"
        if [ "$first_run" -eq 1 ]; then
            first_run=0
            last_activity="$current_activity"
            continue
        fi
        
        if [ "$current_activity" = "$last_activity" ]; then
            continue
        fi
        last_activity="$current_activity"

        activity_name=$(get_name "$current_activity")
        pidfile="$PID_DIR/${INSTANCE_PREFIX}_${activity_name}.pid"

        if is_ready_to_run_tasks "$activity_name" "$pidfile"; then
            run_"${activity_name}"_tasks "$pidfile"
        fi
    done
}

run_event_loop
