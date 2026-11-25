FROM ghcr.io/tiiuae/tii-px4-msgs:sha-77f972d-${TARGETARCH:-amd64}-humble AS px4msgs

FROM ros:humble-ros-core-jammy AS base

RUN --mount=type=bind,from=px4msgs,source=/artifacts,target=/artifacts \
    apt-get update \
    && apt-get install -y --no-install-recommends /artifacts/*.deb \
        libspdlog1 \
        python3-pystache \
        python3-simplejson \
        ros-humble-fastrtps \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

FROM base AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        libspdlog-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Jammy does not package prometheus-cpp; link the metrics libraries statically.
RUN git clone --branch v1.1.0 --depth 1 --recurse-submodules --shallow-submodules \
        https://github.com/jupp0r/prometheus-cpp.git /prometheus-cpp \
    && cmake -S /prometheus-cpp -B /prometheus-cpp/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_PUSH=OFF \
        -DENABLE_TESTING=OFF \
    && cmake --build /prometheus-cpp/build --parallel 2 \
    && cmake --install /prometheus-cpp/build

WORKDIR /src
COPY . .

RUN . /opt/ros/humble/setup.sh \
    && cmake -S . -B /build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DUAGENT_SUPERBUILD=OFF \
        -DUAGENT_USE_SYSTEM_LOGGER=ON \
    && cmake --build /build --parallel 2 \
    && DESTDIR=/install cmake --install /build

FROM base AS runtime

WORKDIR /
COPY --from=builder /install/usr/local/bin/ /usr/local/bin/
COPY --from=builder /install/usr/local/lib/ /usr/local/lib/
COPY --from=builder /prometheus-cpp/LICENSE /usr/share/doc/prometheus-cpp/LICENSE
COPY --from=builder /prometheus-cpp/3rdparty/civetweb/LICENSE.md /usr/share/doc/civetweb/LICENSE.md
COPY LICENSE /usr/share/doc/microxrcedds-agent/LICENSE
COPY entrypoint.sh dds_security_part_mustache.xml agent.refs /

RUN ldconfig

ENTRYPOINT ["/ros_entrypoint.sh", "/entrypoint.sh"]
CMD []
