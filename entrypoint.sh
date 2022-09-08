#!/bin/bash -e

source /opt/ros/galactic/setup.bash

MicroXRCEAgent udp4 --port 2020 --send_port 2019 --refs /agent.refs
