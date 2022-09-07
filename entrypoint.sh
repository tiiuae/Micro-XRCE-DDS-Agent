#!/bin/bash -e

source /opt/ros/galactic/setup.bash

MicroXRCEAgent udp4 --port 2020 --refs /agent.refs
