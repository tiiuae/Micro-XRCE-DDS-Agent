# Given dynamically from CI job.
FROM --platform=${BUILDPLATFORM:-linux/amd64} ghcr.io/tiiuae/fog-ros-sdk:sha-f8defd3-${TARGETARCH:-amd64} AS builder

# Must be defined another time after "FROM" keyword.
ARG TARGETARCH

# SRC_DIR environment variable is defined in the fog-ros-sdk image.
# The same workspace path is used by all ROS2 components.
# See: https://github.com/tiiuae/fog-ros-baseimage/blob/main/Dockerfile.sdk_builder
COPY . $SRC_DIR/microxrcedds_agent

RUN /packaging/build_colcon_sdk.sh ${TARGETARCH:-amd64}
# Even though it is possible to tar the install directory for retrieving it later in runtime image,
# the tar extraction in arm64 emulated on arm64 is still slow. So, we copy the install directory instead

#  ▲               runtime ──┐
#  └── build                 ▼

FROM ghcr.io/tiiuae/fog-ros-baseimage:sha-f8defd3

ENTRYPOINT [ "/entrypoint.sh" ]

HEALTHCHECK --interval=5s \
	CMD fog-health check --metric=messages_from_flightcontroller_count --diff-gte=1.0 \
		--metrics-from=http://localhost:${METRICS_PORT}/metrics --only-if-nonempty=${METRICS_PORT}

RUN apt-get update \
    && apt-get install -y \
        prometheus-cpp \
        civetweb-cpp \
    && rm -rf /var/lib/apt/lists/* \
	&& pip3 install simplejson pystache

RUN mkdir -p /usr/local/lib \
    && mkdir -p /usr/local/bin

COPY --from=builder /main_ws/install/bin/MicroXRCEAgent /usr/local/bin
COPY --from=builder /main_ws/install/lib/libmicroxrcedds_agent.so.2.2.0 /usr/local/lib
RUN ln -s /usr/local/lib/libmicroxrcedds_agent.so.2.2.0 /usr/local/lib/libmicroxrcedds_agent.so.2.2 \
    && ln -s /usr/local/lib/libmicroxrcedds_agent.so.2.2 /usr/local/lib/libmicroxrcedds_agent.so

ENV PATH="/usr/local/bin:$PATH" \
    LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

COPY entrypoint.sh parse_agent_refs.py agent.refs.mustache agent.refs /
