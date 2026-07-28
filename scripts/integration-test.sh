#!/usr/bin/env bash
set -euo pipefail

# Integration tests are ordinary CTest tests carrying the "integration" label.
# The generated services run on the same Compose network as the test runner.
./scripts/build.sh

docker compose -f docker-compose.integration.yml up -d --force-recreate
cleanup() {
  docker compose -f docker-compose.integration.yml down --timeout 30
}
trap cleanup EXIT

docker compose -f docker-compose.cmake.yml run --build --rm cpp-build \
  /bin/bash -lc \
  'ctest --preset docker-debug -L integration --no-tests=ignore'