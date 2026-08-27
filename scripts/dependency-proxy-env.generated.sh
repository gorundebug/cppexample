#!/usr/bin/env bash

# The shared dependency proxy is strictly opt-in. Direct script execution and
# Make targets therefore use exactly the same environment contract.
if [[ -n "${SERVICEGEN_DEPENDENCY_PROXY_DIR:-}" ]]; then
  servicegen_proxy_docker_host="${SERVICEGEN_DEPENDENCY_PROXY_DOCKER_HOST:-host.docker.internal}"
  servicegen_proxy_port="${SERVICEGEN_DEPENDENCY_PROXY_PORT:-${SERVICEGEN_NEXUS_PORT:-18081}}"
  servicegen_proxy_base="http://${servicegen_proxy_docker_host}:${servicegen_proxy_port}/repository"
  servicegen_git_mirror_port="${SERVICEGEN_GIT_MIRROR_PORT:-18084}"
  servicegen_git_mirror_base="http://${servicegen_proxy_docker_host}:${servicegen_git_mirror_port}/cgi-bin/git"

  export SERVICEGEN_CONAN_HOME="${SERVICEGEN_DEPENDENCY_PROXY_DIR}/conan2"
  export SERVICEGEN_GITHUB_RAW_URL="${servicegen_proxy_base}/github-raw"
  export SERVICEGEN_CONAN_REMOTE_URL="${servicegen_proxy_base}/conan-proxy"
  export PIP_INDEX_URL="${servicegen_proxy_base}/pypi-proxy/simple"
  export PIP_TRUSTED_HOST="${servicegen_proxy_docker_host}"
  export SERVICEGEN_APT_UBUNTU_ARCHIVE_URL="${servicegen_proxy_base}/apt-ubuntu-archive"
  export SERVICEGEN_APT_UBUNTU_SECURITY_URL="${servicegen_proxy_base}/apt-ubuntu-security"
  export SERVICEGEN_APT_UBUNTU_PORTS_URL="${servicegen_proxy_base}/apt-ubuntu-ports"
  export SERVICELIB_SOURCE_CONTEXT="${SERVICELIB_SOURCE_CONTEXT:-${servicegen_proxy_base}/github-raw/gorundebug/cppservicelib/archive/refs/tags/v0.2.22.tar.gz}"
  export USERVER_SOURCE_CONTEXT="${USERVER_SOURCE_CONTEXT:-${servicegen_git_mirror_base}/github.com/userver-framework/userver.git#c9f77729c0edce7e423def2d4a4450aa7fc9d259}"
fi