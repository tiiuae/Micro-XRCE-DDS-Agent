#!/bin/bash -e

key_path="/sros-keystore/enclaves/container/key.p11"
#key_path="$MICROXRCE_SROS_KEY_PATH"
source /opt/ros/galactic/setup.bash

keydata="                        <value>$(cat $key_path)</value>"
data_before=$(sed '/MICROXRCE_PRIVATE_KEY/Q' agent.refs)
data_after=$(awk '{if(found) print} /MICROXRCE_PRIVATE_KEY/{found=1}' agent.refs)
echo "${data_before}
${keydata}
${data_after}" > agent.refs.tmp

MicroXRCEAgent udp4 --port 2020 --send_port 2019 --refs /agent.refs.tmp
