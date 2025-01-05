#!/bin/dash
#abcdam
set -e

[ "$1" = "kill" ]                         &&
  pids="$(pgrep -f "konsole --hold -e")"  && 
  echo "Pids to kill: $pids"              && 
  kill $pids                              && 
  exit 0

target="$1"
if [ -z "$target" ]; then
  echo "Usage: $0 <KDE_activity_name>"
  exit 1
fi

IDISP=2
RES="$(xrandr | grep '\bconnected' -A 1 | tail -n 1 | awk '{print $1}')"
CATCHUP_TIME=0.25 # workaround compensation due to lack of direct targeting when spawning app over qdbus api

KDE_APP_BUS='qdbus org.kde.ActivityManager'
API_ACTIVITY='/ActivityManager/Activities'
API_NS='org.kde.ActivityManager.Activities'
QUERY="$KDE_APP_BUS $API_ACTIVITY $API_NS"

GET_CURRENT_ACTIVITY="$QUERY.CurrentActivity"
SET_CURRENT_ACTIVITY="$QUERY.SetCurrentActivity"
LIST_ALL_ACTIVITIES="$QUERY.ListActivities"
GET_ACTIVITY_NAME="$QUERY.ActivityName"

I3_BIN="$(which i3)"
XEPH_BIN="$(which Xephyr)"

setup_xeph() {
    apt install xserver-xephyr -y
    XEPH_BIN="$(which Xephyr)"
}

# creates inner x11 sesh with i3 window mgr @ target activity
run_i3() {
    [ -z "$XEPH_BIN" ] && setup_xeph
    curr_activity=$($GET_CURRENT_ACTIVITY)
    $SET_CURRENT_ACTIVITY $1                                        \
        &&                                                          \
        nohup konsole  --hold -e "$XEPH_BIN :$IDISP -screen $RES" & \
        sleep $CATCHUP_TIME                                         \
        &&                                                          \
        $SET_CURRENT_ACTIVITY $curr_activity                        \
    && DISPLAY=:$IDISP konsole --hold -e "$I3_BIN" &
}

# iter over user's desktop namespaces to confirm && run target
for activity_id in $(${LIST_ALL_ACTIVITIES}); do
    activity_name="$($GET_ACTIVITY_NAME "$activity_id")"

  if [ "$activity_name" = "$target" ]; then
    echo "Found target activity: $activity_name (ID: $activity_id)"
    run_i3 "$activity_id"
    exit 0
  fi
done