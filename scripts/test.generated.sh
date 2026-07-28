#!/usr/bin/env bash
# Generated test command.
set -euo pipefail

# Configure and build first so this command also works with an empty build
# volume on a clean CI runner.
exec docker compose -f docker-compose.cmake.yml run --build --rm cpp-build \
  /bin/bash -lc \
  'source scripts/configure-git-auth.generated.sh &&
   cmake --preset docker-debug \
     -DSERVICEGEN_FETCH_CPP_DEPENDENCIES="${SERVICEGEN_FETCH_CPP_DEPENDENCIES:-OFF}" &&
   cmake --build --preset docker-debug &&
   ctest --preset docker-debug'
