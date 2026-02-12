# Given dynamically from CI job.
FROM --platform=${BUILDPLATFORM:-linux/amd64} ghcr.io/tiiuae/fog-ros-sdk:v3.3.0-${TARGETARCH:-amd64} AS builder

# Must be defined another time after "FROM" keyword.
ARG TARGETARCH

# SRC_DIR environment variable is defined in the fog-ros-sdk image.
# The same workspace path is used by all ROS2 components.
# See: https://github.com/tiiuae/fog-ros-baseimage/blob/main/Dockerfile.sdk_builder
COPY . $SRC_DIR/microxrcedds_agent
COPY PX4-msgs $SRC_DIR/px4-msgs-new

RUN /packaging/build_colcon_sdk.sh ${TARGETARCH:-amd64}
# Even though it is possible to tar the install directory for retrieving it later in runtime image,
# the tar extraction in arm64 emulated on arm64 is still slow. So, we copy the install directory instead

#  ▲               runtime ──┐
#  └── build                 ▼

FROM ghcr.io/tiiuae/fog-ros-baseimage:v3.3.0

ENTRYPOINT [ "/entrypoint.sh" ]

HEALTHCHECK --interval=5s \
	CMD fog-health check --metric=messages_from_flightcontroller_count --diff-gte=1.0 \
		--metrics-from=http://localhost:${METRICS_PORT}/metrics --only-if-nonempty=${METRICS_PORT}

RUN apt update \
    && apt install -y \
        prometheus-cpp \
        civetweb-cpp \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
	&& pip3 install simplejson pystache

RUN mkdir -p /usr/local/lib \
    && mkdir -p /usr/local/bin

COPY --from=builder /main_ws/install/bin/MicroXRCEAgent /usr/local/bin
COPY --from=builder /main_ws/install/lib/libmicroxrcedds_agent.so.2.2.0 /usr/local/lib
RUN ln -s /usr/local/lib/libmicroxrcedds_agent.so.2.2.0 /usr/local/lib/libmicroxrcedds_agent.so.2.2 \
    && ln -s /usr/local/lib/libmicroxrcedds_agent.so.2.2 /usr/local/lib/libmicroxrcedds_agent.so

COPY --from=builder /main_ws/install/lib/libpx4_msgs__*.so /usr/local/lib/
COPY --from=builder /main_ws/install/share/px4_msgs /usr/share/px4_msgs
COPY --from=builder /main_ws/install/lib/python3.10/site-packages/px4_msgs \
     /usr/local/lib/python3.10/dist-packages/px4_msgs
ENV PYTHONPATH="/usr/local/lib/python3.10/dist-packages:$PYTHONPATH" \
    PATH="/usr/local/bin:$PATH" \
    LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

RUN rename 's/\.\.so$/.so/' /usr/local/lib/python3.10/dist-packages/px4_msgs/*.so \
    || mv /usr/local/lib/python3.10/dist-packages/px4_msgs/px4_msgs_s__rosidl_typesupport_c..so /usr/local/lib/python3.10/dist-packages/px4_msgs/px4_msgs_s__rosidl_typesupport_c.so \
    && mv /usr/local/lib/python3.10/dist-packages/px4_msgs/px4_msgs_s__rosidl_typesupport_fastrtps_c..so /usr/local/lib/python3.10/dist-packages/px4_msgs/px4_msgs_s__rosidl_typesupport_fastrtps_c.so \
    && mv /usr/local/lib/python3.10/dist-packages/px4_msgs/px4_msgs_s__rosidl_typesupport_introspection_c..so /usr/local/lib/python3.10/dist-packages/px4_msgs/px4_msgs_s__rosidl_typesupport_introspection_c.so

COPY entrypoint.sh parse_dds_security_part.py dds_security_part_mustache.xml combine_default_profiles.py agent.refs /
