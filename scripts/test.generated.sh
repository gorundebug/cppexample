#!/usr/bin/env bash
set -euo pipefail

# Configure and build first so this command also works with an empty build
# volume on a clean CI runner.
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
   cmake --preset "$SERVICEGEN_CPP_CMAKE_PRESET" \
     -DSERVICEGEN_FETCH_CPP_DEPENDENCIES="${SERVICEGEN_FETCH_CPP_DEPENDENCIES:-OFF}" \
     -DUSERVER_LTO="${USERVER_LTO:-OFF}" &&
   cmake --build --preset "$SERVICEGEN_CPP_CMAKE_PRESET" &&
   ctest --preset "$SERVICEGEN_CPP_CMAKE_PRESET"'