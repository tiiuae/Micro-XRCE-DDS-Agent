FROM ghcr.io/tiiuae/fog-ros-baseimage-builder:v2.0.0 AS builder

COPY . /main_ws/src/

# this:
# 1) builds the application
# 2) packages the application as .deb in /main_ws/

RUN /packaging/build.sh

#  ▲               runtime ──┐
#  └── build                 ▼

FROM ghcr.io/tiiuae/fog-ros-baseimage:v2.0.0

HEALTHCHECK --interval=5s \
	CMD fog-health check --metric=messages_from_flightcontroller_count --diff-gte=1.0 \
		--metrics-from=http://localhost:${METRICS_PORT}/metrics --only-if-nonempty=${METRICS_PORT}

RUN apt-get update && apt-get install -y python3-pip && \
  pip3 install simplejson pystache

ENTRYPOINT /entrypoint.sh
COPY entrypoint.sh /entrypoint.sh
COPY parse_agent_refs.py /parse_agent_refs.py
COPY agent.refs.mustache /agent.refs.mustache
COPY agent.refs /agent.refs

COPY --from=builder /main_ws/ros-*-microxrce-agent_*_amd64.deb /microxrce-agent.deb
RUN dpkg -i /microxrce-agent.deb && rm /microxrce-agent.deb

