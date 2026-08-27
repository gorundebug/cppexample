#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/dependency-proxy-env.generated.sh"

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
  -e CPP_CMAKE_PRESET="$preset" cpp-build \
  /bin/bash -lc \
  'source scripts/configure-git-auth.generated.sh &&
   build_type=Debug; if [[ "$CPP_CMAKE_PRESET" == docker-release ]]; then build_type=Release; fi &&
   ./scripts/run_with_progress.generated.sh "Conan $build_type install" ./scripts/conan-install.generated.sh "$build_type" "/workspace/build/conan-${build_type,,}" &&
   conan_toolchain="$(cat "/workspace/build/conan-${build_type,,}/toolchain.path")" &&
   ./scripts/run_with_progress.generated.sh "Configure $CPP_CMAKE_PRESET" cmake --fresh --preset "$CPP_CMAKE_PRESET" \
     -DCMAKE_TOOLCHAIN_FILE="$conan_toolchain" \
     -DFETCH_CPP_DEPENDENCIES="${FETCH_CPP_DEPENDENCIES:-OFF}" \
     -DUSERVER_LTO="${USERVER_LTO:-OFF}" &&
   ./scripts/run_with_progress.generated.sh "Build $CPP_CMAKE_PRESET" cmake --build --preset "$CPP_CMAKE_PRESET" &&
   ./scripts/run_with_progress.generated.sh "Test $CPP_CMAKE_PRESET" ctest --preset "$CPP_CMAKE_PRESET"'