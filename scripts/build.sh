#!/usr/bin/env bash
set -euo pipefail

# Docker is the canonical C++ build environment. The compose file deliberately
# leaves the platform unset so Docker selects the runner's native architecture.
exec docker compose -f docker-compose.cmake.yml run --build --rm cpp-build \
  /bin/bash -lc \
  'cmake --preset docker-debug && cmake --build --preset docker-debug'