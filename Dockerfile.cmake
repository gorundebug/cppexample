# syntax=docker/dockerfile:1
FROM servicelib-source AS servicelib-source
FROM userver-source AS userver-source

FROM --platform=$TARGETPLATFORM ubuntu:24.04 AS development

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

COPY docker/userver-packages-ubuntu-24.04.txt /tmp/userver-packages.txt

RUN rm -f /etc/apt/apt.conf.d/docker-clean
RUN --mount=type=cache,id=servicegen-apt-lists-${TARGETARCH},target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,id=servicegen-apt-cache-${TARGETARCH},target=/var/cache/apt,sharing=locked \
    apt-get update \
    && xargs apt-get install --yes --no-install-recommends \
       ca-certificates locales python3-pip \
       < /tmp/userver-packages.txt \
    && locale-gen en_US.UTF-8 \
    && rm -f /tmp/userver-packages.txt

COPY --from=servicelib-source / /opt/servicelib
COPY --from=userver-source / /opt/userver

WORKDIR /workspace

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV SERVICELIB_SOURCE_DIR=/opt/servicelib
ENV USERVER_SOURCE_DIR=/opt/userver
ENV CPM_SOURCE_CACHE=/var/cache/cpm

FROM development AS runtime-builder

ARG USERVER_LTO=ON
ARG SERVICEGEN_RUNTIME_STRIP=ON
ARG SERVICEGEN_EXAMPLE_PROFILE=function-call
COPY . /workspace
RUN --mount=type=cache,id=cppexample-runtime-build-v2-${TARGETARCH}-${SERVICEGEN_EXAMPLE_PROFILE},target=/workspace/build,sharing=locked \
    --mount=type=cache,id=servicegen-userver-cpm-v1-${TARGETARCH},target=/var/cache/cpm,sharing=locked \
    --mount=type=cache,id=cppexample-runtime-ccache-${TARGETARCH},target=/ccache \
    CCACHE_DIR=/ccache ./scripts/run_with_progress.generated.sh "Release configure" cmake --preset docker-release \
      -DSERVICEGEN_FETCH_CPP_DEPENDENCIES=OFF \
      -DBUILD_TESTING=OFF \
      -DUSERVER_BUILD_TESTS=OFF \
      -DUSERVER_FEATURE_UTEST=ON \
      -DUSERVER_FEATURE_TESTSUITE=OFF \
      -DUSERVER_LTO="${USERVER_LTO}" \
    && ./scripts/run_with_progress.generated.sh "Release build" cmake --build --preset docker-release \
      --target example_analytics_service example_inventory_service example_order_service --parallel \
    && mkdir -p /opt/service-bin /opt/runtime-libs \
    && mkdir -p /opt/runtime-libs/analyticsservice \
    && cp /workspace/build/analyticsservice/example_analytics_service /opt/service-bin/example_analytics_service \
    && mkdir -p /opt/runtime-libs/inventoryservice \
    && cp /workspace/build/inventoryservice/example_inventory_service /opt/service-bin/example_inventory_service \
    && mkdir -p /opt/runtime-libs/orderservice \
    && cp /workspace/build/orderservice/example_order_service /opt/service-bin/example_order_service \
    && if [ "${SERVICEGEN_RUNTIME_STRIP}" = "ON" ]; then \
         strip --strip-unneeded /opt/service-bin/*; \
       fi \
    && ldd /opt/service-bin/example_analytics_service \
       | awk '/=> \/.*\// {print $3} /\/ld-linux/ {print $1}' \
       | sort -u | while read -r library; do \
         cp -L "$library" "/opt/runtime-libs/analyticsservice/$(basename "$library")"; \
       done \
    && ldd /opt/service-bin/example_inventory_service \
       | awk '/=> \/.*\// {print $3} /\/ld-linux/ {print $1}' \
       | sort -u | while read -r library; do \
         cp -L "$library" "/opt/runtime-libs/inventoryservice/$(basename "$library")"; \
       done \
    && ldd /opt/service-bin/example_order_service \
       | awk '/=> \/.*\// {print $3} /\/ld-linux/ {print $1}' \
       | sort -u | while read -r library; do \
         cp -L "$library" "/opt/runtime-libs/orderservice/$(basename "$library")"; \
       done \
    && true

FROM ubuntu:24.04 AS runtime-base

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH=/usr/local/lib/servicegen
WORKDIR /app

FROM runtime-base AS runtime-analyticsservice
COPY --from=runtime-builder /opt/runtime-libs/analyticsservice /usr/local/lib/servicegen
COPY --from=runtime-builder /opt/service-bin/example_analytics_service /usr/local/bin/example_analytics_service
COPY analyticsservice/static_config.yaml /app/static_config.yaml
COPY analyticsservice/config/*.yaml /app/config/
ENTRYPOINT ["/usr/local/bin/example_analytics_service"]

FROM runtime-base AS runtime-inventoryservice
COPY --from=runtime-builder /opt/runtime-libs/inventoryservice /usr/local/lib/servicegen
COPY --from=runtime-builder /opt/service-bin/example_inventory_service /usr/local/bin/example_inventory_service
COPY inventoryservice/static_config.yaml /app/static_config.yaml
COPY inventoryservice/config/*.yaml /app/config/
ENTRYPOINT ["/usr/local/bin/example_inventory_service"]

FROM runtime-base AS runtime-orderservice
COPY --from=runtime-builder /opt/runtime-libs/orderservice /usr/local/lib/servicegen
COPY --from=runtime-builder /opt/service-bin/example_order_service /usr/local/bin/example_order_service
COPY orderservice/static_config.yaml /app/static_config.yaml
COPY orderservice/config/*.yaml /app/config/
ENTRYPOINT ["/usr/local/bin/example_order_service"]