#!/bin/bash -e

source /opt/ros/galactic/setup.bash
_term() {
        # FILL UP PROCESS SEARCH PATTERN HERE TO FIND PROPER PROCESS FOR SIGINT:
        pattern="MicroXRCEAgent"

        pid_value="$(ps -ax | grep $pattern | grep -v grep | awk '{ print $1 }')"
        if [ "$pid_value" != "" ]; then
                pid=$pid_value
                echo "Send SIGINT to pid $pid"
        else
                pid=1
                echo "Pattern not found, send SIGINT to pid $pid"
        fi
        kill -s SIGINT $pid
}
# Use SIGTERM or TERM, does not seem to make any difference.
trap _term TERM

MicroXRCEAgent udp4 --port 2020 --send_port 2019 --refs /agent.refs &

child=$!
echo "Waiting for pid $child"
# * Calling "wait" will then wait for the job with the specified by $child to finish, or for any signals to be fired.
#   Due to "or for any signals to be fired", "wait" will also handle SIGTERM and it will shutdown before
#   the node ends gracefully.
#   The solution is to add a second "wait" call and remove the trap between the two calls.
# * Do not use -e flag in the first wait call because wait will exit with error after catching SIGTERM.
set +e
wait $child
trap - TERM
wait $child
set -e
RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo "ERROR: MicroXRCEAgent failed with code $RESULT" >&2
    exit $RESULT
else
    echo "INFO: MicroXRCEAgent finished successfully, but returning 125 code for docker to restart properly." >&2
    exit 125
fi
