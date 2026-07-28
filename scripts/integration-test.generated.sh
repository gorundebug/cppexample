#!/usr/bin/env bash
# Generated integration test command.
set -euo pipefail

# Integration tests are ordinary CTest tests carrying the "integration" label.
# The generated services run on the same Compose network as the test runner.
./scripts/build.generated.sh

docker compose -f docker-compose.integration.generated.yml up -d --force-recreate
cleanup() {
  docker compose -f docker-compose.integration.generated.yml down --timeout 30
}
trap cleanup EXIT

docker compose -f docker-compose.cmake.yml run --build --rm cpp-build \
  /bin/bash -lc \
  'ctest --preset docker-debug -L integration --no-tests=ignore'
