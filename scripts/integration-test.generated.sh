#!/usr/bin/env bash
set -euo pipefail

# Integration tests are ordinary CTest tests carrying the "integration" label.
# The generated services run on the same Compose network as the test runner.
preset="${1:-docker-debug}"
case "$preset" in
  docker-debug|docker-release) ;;
  *)
    echo "unsupported C++ Docker preset: $preset" >&2
    exit 2
    ;;
esac

./scripts/build.generated.sh "$preset"

docker compose -f docker-compose.integration.generated.yml up -d --force-recreate
cleanup() {
  docker compose -f docker-compose.integration.generated.yml down --timeout 30
}
trap cleanup EXIT

docker compose -f docker-compose.cmake.generated.yml run --build --rm \
  -e CPP_CMAKE_PRESET="$preset" cpp-build \
  /bin/bash -lc \
  'ctest --test-dir /workspace/build --output-on-failure -L integration --no-tests=ignore'