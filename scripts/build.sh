#!/usr/bin/env bash
set -euo pipefail

# Docker is the canonical C++ build environment. The compose file deliberately
# leaves the platform unset so Docker selects the runner's native architecture.
exec docker compose -f docker-compose.cmake.yml run --build --rm cpp-build \
  /bin/bash -lc \
  'source scripts/configure-git-auth.generated.sh &&
   cmake --preset docker-debug \
     -DSERVICEGEN_FETCH_CPP_DEPENDENCIES="${SERVICEGEN_FETCH_CPP_DEPENDENCIES:-OFF}" &&
   cmake --build --preset docker-debug'
