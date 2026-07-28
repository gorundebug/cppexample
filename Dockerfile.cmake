# syntax=docker/dockerfile:1
FROM servicelib-source AS servicelib-source
FROM userver-source AS userver-source

FROM --platform=$TARGETPLATFORM ubuntu:26.04

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

COPY docker/userver-packages-ubuntu-26.04.txt /tmp/userver-packages.txt

RUN apt-get update \
    && xargs apt-get install --yes --no-install-recommends \
       ca-certificates locales python3-pip \
       < /tmp/userver-packages.txt \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/* /tmp/userver-packages.txt

COPY --from=servicelib-source / /opt/servicelib
COPY --from=userver-source / /opt/userver
COPY tools/userver /opt/userver-patches

RUN /opt/userver-patches/apply-patches.generated.sh /opt/userver

WORKDIR /workspace

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV SERVICELIB_SOURCE_DIR=/opt/servicelib
ENV USERVER_SOURCE_DIR=/opt/userver