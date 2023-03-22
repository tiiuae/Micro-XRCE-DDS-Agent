FROM ghcr.io/tiiuae/fog-ros-baseimage-builder:riscv64_support as builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        prometheus-cpp-dev \
        civetweb-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /main_ws/src/

RUN /packaging/build_colcon.sh

#  ▲               runtime ──┐
#  └── build                 ▼

FROM ghcr.io/tiiuae/fog-ros-baseimage:riscv64_support

HEALTHCHECK --interval=5s CMD /healthcheck.sh

RUN apt-get update \
    && apt-get install -y \
        prometheus-cpp \
        civetweb-cpp \
    && rm -rf /var/lib/apt/lists/* \
	&& pip3 install simplejson pystache

RUN mkdir -p /usr/local/lib \
    && mkdir -p /usr/local/bin

COPY --from=builder /main_ws/install/microxrcedds_agent/bin/MicroXRCEAgent /usr/local/bin
COPY --from=builder /main_ws/install/microxrcedds_agent/lib64/libmicroxrcedds_agent.so.2.2.0 /usr/local/lib
RUN ln -s /usr/local/lib/libmicroxrcedds_agent.so.2.2.0 /usr/local/lib/libmicroxrcedds_agent.so.2.2 \
    && ln -s /usr/local/lib/libmicroxrcedds_agent.so.2.2 /usr/local/lib/libmicroxrcedds_agent.so

ENV PATH="/usr/local/bin:$PATH" \
    LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

COPY healthcheck.sh /healthcheck.sh
COPY entrypoint.sh /entrypoint.sh

COPY parse_agent_refs.py /parse_agent_refs.py
COPY agent.refs.mustache /agent.refs.mustache
COPY agent.refs /agent.refs

ENTRYPOINT [ "/entrypoint.sh" ]
