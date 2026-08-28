ARG DEPENDENCY_DOCKER_REGISTRY=docker.io
FROM servicelib-source AS servicelib-source
FROM userver-source AS userver-source
FROM module-model_cpp AS module-model_cpp

FROM --platform=$TARGETPLATFORM ${DEPENDENCY_DOCKER_REGISTRY}/library/ubuntu:24.04 AS development

ARG TARGETARCH
ARG DEPENDENCY_GITHUB_RAW_URL=
ARG DEPENDENCY_APT_UBUNTU_ARCHIVE_URL=
ARG DEPENDENCY_APT_UBUNTU_SECURITY_URL=
ARG DEPENDENCY_APT_UBUNTU_PORTS_URL=
ARG DEPENDENCY_CONAN_REMOTE_URL=
ARG PIP_INDEX_URL=https://pypi.org/simple
ARG PIP_TRUSTED_HOST=
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV DEPENDENCY_GITHUB_RAW_URL=${DEPENDENCY_GITHUB_RAW_URL}
ENV DEPENDENCY_CONAN_REMOTE_URL=${DEPENDENCY_CONAN_REMOTE_URL}
COPY dependency-download-mirrors.generated.env /etc/servicegen/dependency-download-mirrors.generated.env
COPY dependency-download-mirrors.env /etc/servicegen/dependency-download-mirrors.env
COPY dependency-download-env.generated.sh /usr/local/bin/servicegen-download-env
SHELL ["/usr/local/bin/servicegen-download-env", "/bin/sh", "-c"]

COPY docker/userver-packages-ubuntu-24.04.txt /tmp/userver-packages.txt

RUN if [ -n "$DEPENDENCY_APT_UBUNTU_ARCHIVE_URL$DEPENDENCY_APT_UBUNTU_SECURITY_URL$DEPENDENCY_APT_UBUNTU_PORTS_URL" ]; then \
      find /etc/apt -type f \( -name '*.list' -o -name '*.sources' \) -exec sed -i \
        -e "s|http://archive.ubuntu.com/ubuntu|$DEPENDENCY_APT_UBUNTU_ARCHIVE_URL|g" \
        -e "s|http://security.ubuntu.com/ubuntu|$DEPENDENCY_APT_UBUNTU_SECURITY_URL|g" \
        -e "s|http://ports.ubuntu.com/ubuntu-ports|$DEPENDENCY_APT_UBUNTU_PORTS_URL|g" {} +; \
    fi

RUN rm -f /etc/apt/apt.conf.d/docker-clean
RUN --mount=type=cache,id=servicegen-apt-lists-${TARGETARCH},target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,id=servicegen-apt-cache-${TARGETARCH},target=/var/cache/apt,sharing=locked \
    apt-get update \
    && xargs apt-get install --yes --no-install-recommends \
       ca-certificates locales python3-pip \
       < /tmp/userver-packages.txt \
    && locale-gen en_US.UTF-8 \
    && rm -f /tmp/userver-packages.txt

RUN python3 -m venv /opt/conan \
    && PIP_TRUSTED_HOST="$PIP_TRUSTED_HOST" \
       /opt/conan/bin/pip install --no-cache-dir --index-url "$PIP_INDEX_URL" \
       conan==2.31.1
ENV PATH=/opt/conan/bin:$PATH
ENV CONAN_HOME=/conan
ENV PIP_INDEX_URL=${PIP_INDEX_URL}
ENV PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}

COPY --from=servicelib-source / /tmp/servicelib-source
RUN set -eu; \
    source_dir=/tmp/servicelib-source; \
    archive=$(find "$source_dir" -mindepth 1 -maxdepth 1 -type f \( -name context -o -name '*.tar' -o -name '*.tar.gz' -o -name '*.tgz' -o -name '*.tar.xz' \) -print -quit); \
    if [ -n "$archive" ]; then \
      mkdir -p /tmp/servicelib-archive; \
      tar -xf "$archive" -C /tmp/servicelib-archive; \
      source_dir=/tmp/servicelib-archive; \
    fi; \
    manifest="$source_dir/CMakeLists.txt"; \
    if [ ! -f "$manifest" ]; then manifest=$(find "$source_dir" -mindepth 2 -maxdepth 2 -type f -name CMakeLists.txt -print -quit); fi; \
    if [ -z "$manifest" ]; then echo "cppservicelib source context has no CMakeLists.txt" >&2; exit 1; fi; \
    source_dir=${manifest%/CMakeLists.txt}; \
    if [ -z "$source_dir" ] || [ "$source_dir" = "/" ]; then echo "unsafe cppservicelib source directory" >&2; exit 1; fi; \
    mkdir -p /opt/servicelib; \
    cp -a "$source_dir/." /opt/servicelib/; \
    rm -rf /tmp/servicelib-source

COPY --from=userver-source / /tmp/userver-source
RUN set -eu; \
    source_dir=/tmp/userver-source; \
    archive=$(find "$source_dir" -mindepth 1 -maxdepth 1 -type f \( -name context -o -name '*.tar' -o -name '*.tar.gz' -o -name '*.tgz' -o -name '*.tar.xz' \) -print -quit); \
    if [ -n "$archive" ]; then \
      mkdir -p /tmp/userver-archive; \
      tar -xf "$archive" -C /tmp/userver-archive; \
      source_dir=/tmp/userver-archive; \
    fi; \
    manifest="$source_dir/CMakeLists.txt"; \
    if [ ! -f "$manifest" ]; then manifest=$(find "$source_dir" -mindepth 2 -maxdepth 2 -type f -name CMakeLists.txt -print -quit); fi; \
    if [ -z "$manifest" ]; then echo "userver source context has no CMakeLists.txt" >&2; exit 1; fi; \
    source_dir=${manifest%/CMakeLists.txt}; \
    if [ -z "$source_dir" ] || [ "$source_dir" = "/" ]; then echo "unsafe userver source directory" >&2; exit 1; fi; \
    mkdir -p /opt/userver; \
    cp -a "$source_dir/." /opt/userver/; \
    rm -rf /tmp/userver-source

WORKDIR /workspace
COPY --from=module-model_cpp / /tmp/module-model_cpp-source
RUN set -eu; \
    source_dir=/tmp/module-model_cpp-source; \
    archive=$(find "$source_dir" -mindepth 1 -maxdepth 1 -type f \( -name context -o -name '*.tar' -o -name '*.tar.gz' -o -name '*.tgz' -o -name '*.tar.xz' \) -print -quit); \
    if [ -n "$archive" ]; then \
      mkdir -p /tmp/module-model_cpp-archive; \
      tar -xf "$archive" -C /tmp/module-model_cpp-archive; \
      source_dir=/tmp/module-model_cpp-archive; \
    fi; \
    manifest=$(find "$source_dir" -type f -path '*/model_cpp/CMakeLists.txt' -print -quit); \
    if [ -z "$manifest" ]; then manifest="$source_dir/CMakeLists.txt"; fi; \
    if [ ! -f "$manifest" ]; then manifest=$(find "$source_dir" -mindepth 2 -maxdepth 2 -type f -name CMakeLists.txt -print -quit); fi; \
    if [ -z "$manifest" ] || [ ! -f "$manifest" ]; then echo "module model_cpp source context has no CMakeLists.txt" >&2; exit 1; fi; \
    source_dir=${manifest%/CMakeLists.txt}; \
    mkdir -p /workspace/modules/model_cpp; \
    cp -a "$source_dir/." /workspace/modules/model_cpp/; \
    rm -rf /tmp/module-model_cpp-source /tmp/module-model_cpp-archive

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV SERVICELIB_SOURCE_DIR=/opt/servicelib
ENV CPPSERVICELIB_SOURCE_DIR=/opt/servicelib
ENV USERVER_SOURCE_DIR=/opt/userver

FROM development AS runtime-builder

ARG USERVER_LTO=ON
ARG RUNTIME_STRIP=ON
ARG SERVICEGEN_EXAMPLE_PROFILE=function-call
COPY . /workspace
RUN --mount=type=cache,id=cppexample-runtime-build-v2-${TARGETARCH}-${SERVICEGEN_EXAMPLE_PROFILE},target=/workspace/build,sharing=locked \
    --mount=type=cache,id=cppexample-runtime-ccache-${TARGETARCH},target=/ccache \
    --mount=type=cache,id=servicegen-conan2-${TARGETARCH},target=/conan,sharing=locked \
    ./scripts/run_with_progress.generated.sh "Conan Release install" \
      ./scripts/conan-install.generated.sh Release /workspace/build/conan-release \
    && conan_toolchain="$(cat /workspace/build/conan-release/toolchain.path)" \
    && CCACHE_DIR=/ccache ./scripts/run_with_progress.generated.sh "Release configure" cmake --preset docker-release \
      --fresh \
      -DCMAKE_TOOLCHAIN_FILE="${conan_toolchain}" \
      -DFETCH_CPP_DEPENDENCIES=OFF \
      -DBUILD_TESTING=OFF \
      -DUSERVER_BUILD_TESTS=OFF \
      -DUSERVER_FEATURE_UTEST=OFF \
      -DUSERVER_FEATURE_TESTSUITE=OFF \
      -DUSERVER_LTO="${USERVER_LTO}" \
    && ./scripts/run_with_progress.generated.sh "Release build" cmake --build --preset docker-release \
      --target example_analytics_service --parallel \
    && mkdir -p /opt/service-bin /opt/runtime-libs \
    && mkdir -p /opt/runtime-libs/analyticsservice \
    && cp /workspace/build/example_analytics_service /opt/service-bin/example_analytics_service \
    && if [ "${RUNTIME_STRIP}" = "ON" ]; then \
         strip --strip-unneeded /opt/service-bin/*; \
       fi \
    && ldd /opt/service-bin/example_analytics_service \
       | awk '/=> \/.*\// {print $3} /\/ld-linux/ {print $1}' \
       | sort -u | while read -r library; do \
         cp -L "$library" "/opt/runtime-libs/analyticsservice/$(basename "$library")"; \
       done \
    && true

FROM ${DEPENDENCY_DOCKER_REGISTRY}/library/ubuntu:24.04 AS runtime-base

ARG DEBIAN_FRONTEND=noninteractive
ARG DEPENDENCY_APT_UBUNTU_ARCHIVE_URL=
ARG DEPENDENCY_APT_UBUNTU_SECURITY_URL=
ARG DEPENDENCY_APT_UBUNTU_PORTS_URL=
RUN if [ -n "$DEPENDENCY_APT_UBUNTU_ARCHIVE_URL$DEPENDENCY_APT_UBUNTU_SECURITY_URL$DEPENDENCY_APT_UBUNTU_PORTS_URL" ]; then \
      find /etc/apt -type f \( -name '*.list' -o -name '*.sources' \) -exec sed -i \
        -e "s|http://archive.ubuntu.com/ubuntu|$DEPENDENCY_APT_UBUNTU_ARCHIVE_URL|g" \
        -e "s|http://security.ubuntu.com/ubuntu|$DEPENDENCY_APT_UBUNTU_SECURITY_URL|g" \
        -e "s|http://ports.ubuntu.com/ubuntu-ports|$DEPENDENCY_APT_UBUNTU_PORTS_URL|g" {} +; \
    fi
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ENV LD_LIBRARY_PATH=/usr/local/lib/servicegen
WORKDIR /app

FROM runtime-base AS runtime-analyticsservice
COPY --from=runtime-builder /opt/runtime-libs/analyticsservice /usr/local/lib/servicegen
COPY --from=runtime-builder /opt/service-bin/example_analytics_service /usr/local/bin/example_analytics_service
COPY static_config.yaml /app/static_config.yaml
COPY config/*.yaml /app/config/
ENTRYPOINT ["/usr/local/bin/example_analytics_service"]