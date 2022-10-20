#!/bin/bash -e

unset FASTRTPS_DEFAULT_PROFILES_FILE

./parse_agent_refs.py /enclave

MicroXRCEAgent udp4 --port 2020 --send_port 2019 --refs /enclave/agent.refs
