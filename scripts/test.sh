#!/usr/bin/env bash
set -euo pipefail

# Configure and build first so this command also works with an empty build
# volume on a clean CI runner.
exec docker compose -f docker-compose.cmake.yml run --build --rm cpp-build \
  /bin/bash -lc \
  'cmake --preset docker-debug &&
   cmake --build --preset docker-debug &&
   ctest --preset docker-debug'