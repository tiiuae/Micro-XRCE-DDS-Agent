#!/bin/bash

if [ $(uname -m) != x86_64 ]; then
    exit 0
fi

fog-health check --metric=messages_from_flightcontroller_count --diff-gte=1.0 \
    --metrics-from=http://localhost:${METRICS_PORT}/metrics --only-if-nonempty=${METRICS_PORT}

exit $?
