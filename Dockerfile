FROM ghcr.io/tiiuae/fog-ros-baseimage:builder-3dcb78d AS builder

COPY . /main_ws/src/

# this:
# 1) builds the application
# 2) packages the application as .deb in /main_ws/

RUN /packaging/build.sh

#  ▲               runtime ──┐
#  └── build                 ▼

FROM ghcr.io/tiiuae/fog-ros-baseimage:sha-3dcb78d

COPY --from=builder /main_ws/ros-*-microxrce-agent_*_amd64.deb /microxrce-agent.deb

RUN dpkg -i /microxrce-agent.deb && rm /microxrce-agent.deb
