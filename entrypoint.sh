#!/bin/bash -e

./parse_agent_refs.py

MicroXRCEAgent udp4 --port 2020 --send_port 2019 --refs /agent.refs
