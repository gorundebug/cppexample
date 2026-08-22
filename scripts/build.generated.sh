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

exec docker compose -f docker-compose.cmake.generated.yml run --build --rm \
  -e SERVICEGEN_CPP_CMAKE_PRESET="$preset" cpp-build \
  /bin/bash -lc \
  'source scripts/configure-git-auth.generated.sh &&
   ./scripts/run_with_progress.generated.sh "Configure $SERVICEGEN_CPP_CMAKE_PRESET" cmake --preset "$SERVICEGEN_CPP_CMAKE_PRESET" \
     -DSERVICEGEN_FETCH_CPP_DEPENDENCIES="${SERVICEGEN_FETCH_CPP_DEPENDENCIES:-OFF}" \
     -DSERVICEGEN_ENABLE_OTLP_TRACING="${SERVICEGEN_ENABLE_OTLP_TRACING:-OFF}" \
     -DUSERVER_LTO="${USERVER_LTO:-OFF}" &&
   ./scripts/run_with_progress.generated.sh "Build $SERVICEGEN_CPP_CMAKE_PRESET" cmake --build --preset "$SERVICEGEN_CPP_CMAKE_PRESET"'