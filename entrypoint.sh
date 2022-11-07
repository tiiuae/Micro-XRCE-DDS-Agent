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
trap _term SIGTERM

MicroXRCEAgent udp4 --port 2020 --send_port 2019 --refs /agent.refs &

child=$!
echo "Waiting for pid $child"
wait $child
