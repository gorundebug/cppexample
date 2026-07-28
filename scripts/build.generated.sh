#!/usr/bin/env bash
set -euo pipefail

# Docker is the canonical C++ build environment. The compose file deliberately
# leaves the platform unset so Docker selects the runner's native architecture.
preset="${1:-docker-debug}"
case "$preset" in
  docker-debug|docker-release) ;;
  *)
    echo "unsupported C++ Docker preset: $preset" >&2
    exit 2
    ;;
esac

exec docker compose -f docker-compose.cmake.yml run --build --rm \
  -e SERVICEGEN_CPP_CMAKE_PRESET="$preset" cpp-build \
  /bin/bash -lc \
  'source scripts/configure-git-auth.generated.sh &&
   cmake --preset "$SERVICEGEN_CPP_CMAKE_PRESET" \
     -DSERVICEGEN_FETCH_CPP_DEPENDENCIES="${SERVICEGEN_FETCH_CPP_DEPENDENCIES:-OFF}" \
     -DUSERVER_LTO="${USERVER_LTO:-OFF}" &&
   cmake --build --preset "$SERVICEGEN_CPP_CMAKE_PRESET"'