#!/usr/bin/env bash

# The shared dependency proxy is strictly opt-in. Direct script execution and
# Make targets therefore use exactly the same environment contract.
if [[ -n "${DEPENDENCY_PROXY_DIR:-}" ]]; then
  dependency_proxy_host="${DEPENDENCY_PROXY_HOST:-localhost}"
  dependency_proxy_docker_host="${DEPENDENCY_PROXY_DOCKER_HOST:-host.docker.internal}"
  dependency_proxy_port="${DEPENDENCY_PROXY_PORT:-18081}"
  dependency_proxy_base="http://${dependency_proxy_docker_host}:${dependency_proxy_port}/repository"
  dependency_git_mirror_port="${DEPENDENCY_GIT_MIRROR_PORT:-18084}"
  dependency_git_mirror_base="http://${dependency_proxy_docker_host}:${dependency_git_mirror_port}/cgi-bin/git"

  export DEPENDENCY_CONAN_HOME="${DEPENDENCY_PROXY_DIR}/conan2"
  export DEPENDENCY_DOCKER_REGISTRY="${dependency_proxy_host}:${DEPENDENCY_PROXY_DOCKER_PORT:-18083}"
  export DEPENDENCY_GITHUB_RAW_URL="${dependency_proxy_base}/github-raw"
  export DEPENDENCY_CONAN_REMOTE_URL="${dependency_proxy_base}/conan-group"
  export DEPENDENCY_CONAN_UPLOAD_URL="${dependency_proxy_base}/conan-hosted"
  export DEPENDENCY_CONAN_PUBLISH=1
  export DEPENDENCY_CONAN_CREDENTIAL_FILE="${DEPENDENCY_PROXY_DIR%/}/conan.publisher.credential"
  export PIP_INDEX_URL="${dependency_proxy_base}/pypi-proxy/simple"
  export PIP_TRUSTED_HOST="${dependency_proxy_docker_host}"
  export DEPENDENCY_APT_UBUNTU_ARCHIVE_URL="${dependency_proxy_base}/apt-ubuntu-archive"
  export DEPENDENCY_APT_UBUNTU_SECURITY_URL="${dependency_proxy_base}/apt-ubuntu-security"
  export DEPENDENCY_APT_UBUNTU_PORTS_URL="${dependency_proxy_base}/apt-ubuntu-ports"
  export SERVICELIB_SOURCE_CONTEXT="${SERVICELIB_SOURCE_CONTEXT:-${dependency_git_mirror_base}/github.com/gorundebug/cppservicelib.git#v0.2.33}"
  export USERVER_SOURCE_CONTEXT="${USERVER_SOURCE_CONTEXT:-${dependency_git_mirror_base}/github.com/userver-framework/userver.git#c9f77729c0edce7e423def2d4a4450aa7fc9d259}"
fi