#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/dependency-proxy-env.generated.sh"

sanitizer="${1:?expected asan or tsan}"
case "$sanitizer" in
  asan)
    cmake_options=(
      -DSERVICEGEN_ASAN=ON
      -DSERVICEGEN_UBSAN=ON
      '-DUSERVER_SANITIZE=addr;ub'
    )
    ;;
  tsan)
    cmake_options=(
      -DSERVICEGEN_TSAN=ON
      -DUSERVER_SANITIZE=thread
    )
    ;;
  *)
    echo "unsupported sanitizer: $sanitizer" >&2
    exit 2
    ;;
esac

options="${cmake_options[*]}"
exec docker compose -f docker-compose.cmake.generated.yml run --build --rm \
  -e SERVICEGEN_CPP_SANITIZER="$sanitizer" \
  -e SERVICEGEN_CPP_SANITIZER_OPTIONS="$options" cpp-build \
  /bin/bash -lc \
  'set -euo pipefail
   source scripts/configure-git-auth.generated.sh
   build_dir="build/sanitizers/$SERVICEGEN_CPP_SANITIZER"
   if [[ "$SERVICEGEN_CPP_SANITIZER" == "tsan" ]]; then
     export CC=clang
     export CXX=clang++
     conan_dir="build/conan-tsan"
     ./scripts/conan-install.generated.sh Debug "$conan_dir" \
       -s:h compiler=clang \
       -s:h compiler.version=18 \
       -s:h compiler.cppstd=20 \
       -s:h compiler.libcxx=libstdc++11
   else
     conan_dir="build/conan-debug"
     ./scripts/conan-install.generated.sh Debug "$conan_dir"
   fi
   conan_toolchain="$(cat "$conan_dir/toolchain.path")"
   cmake -S . -B "$build_dir" -G Ninja \
     --fresh \
     -DCMAKE_BUILD_TYPE=Debug \
     -DCMAKE_TOOLCHAIN_FILE="$conan_toolchain" \
     -DUSERVER_SOURCE_DIR="$USERVER_SOURCE_DIR" \
     -DSERVICELIB_SOURCE_DIR="$CPPSERVICELIB_SOURCE_DIR" \
     -DFETCH_CPP_DEPENDENCIES=OFF \
     $SERVICEGEN_CPP_SANITIZER_OPTIONS
   cmake --build "$build_dir" --parallel
   case "$SERVICEGEN_CPP_SANITIZER" in
     asan)
       ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 \
       UBSAN_OPTIONS=halt_on_error=1 \
         ctest --test-dir "$build_dir" --output-on-failure
       ;;
     tsan)
       TSAN_OPTIONS=halt_on_error=1 \
         ctest --test-dir "$build_dir" --output-on-failure
       ;;
   esac'