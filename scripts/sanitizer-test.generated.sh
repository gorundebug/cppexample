#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/dependency-proxy-env.generated.sh"

sanitizer="${1:?expected asan or tsan}"
case "$sanitizer" in
  asan)
    cmake_options=(
      -DSERVICEGEN_ASAN=ON
      -DSERVICEGEN_UBSAN=ON
    )
    conan_sanitizer="Address"
    conan_compile_flags='["-fsanitize=address,undefined","-fno-omit-frame-pointer"]'
    conan_link_flags='["-fsanitize=address,undefined"]'
    ;;
  tsan)
    cmake_options=(-DSERVICEGEN_TSAN=ON)
    conan_sanitizer="Thread"
    conan_compile_flags='["-fsanitize=thread","-fno-omit-frame-pointer"]'
    conan_link_flags='["-fsanitize=thread"]'
    ;;
  *)
    echo "unsupported sanitizer: $sanitizer" >&2
    exit 2
    ;;
esac

options="${cmake_options[*]}"
exec docker compose -f docker-compose.cmake.generated.yml run --build --rm \
  -e SERVICEGEN_CPP_SANITIZER="$sanitizer" \
  -e SERVICEGEN_CPP_SANITIZER_OPTIONS="$options" \
  -e SERVICEGEN_CPP_CONAN_SANITIZER="$conan_sanitizer" \
  -e SERVICEGEN_CPP_CONAN_COMPILE_FLAGS="$conan_compile_flags" \
  -e SERVICEGEN_CPP_CONAN_LINK_FLAGS="$conan_link_flags" cpp-build \
  /bin/bash -lc \
  'set -euo pipefail
   source scripts/configure-git-auth.generated.sh
   build_dir="build/sanitizers/$SERVICEGEN_CPP_SANITIZER"
   conan_dir="build/conan-sanitizers/$SERVICEGEN_CPP_SANITIZER"
   ./scripts/conan-install.generated.sh RelWithDebInfo "$conan_dir" \
     -s:h "compiler.sanitizer=$SERVICEGEN_CPP_CONAN_SANITIZER" \
     -c:h "tools.build:cflags=$SERVICEGEN_CPP_CONAN_COMPILE_FLAGS" \
     -c:h "tools.build:cxxflags=$SERVICEGEN_CPP_CONAN_COMPILE_FLAGS" \
     -c:h "tools.build:sharedlinkflags=$SERVICEGEN_CPP_CONAN_LINK_FLAGS" \
     -c:h "tools.build:exelinkflags=$SERVICEGEN_CPP_CONAN_LINK_FLAGS"
   conan_toolchain="$(cat "$conan_dir/toolchain.path")"
   cmake -S . -B "$build_dir" -G Ninja \
     --fresh \
     -DCMAKE_BUILD_TYPE=RelWithDebInfo \
     -DCMAKE_TOOLCHAIN_FILE="$conan_toolchain" \
     -DSERVICEGEN_FETCH_CPP_DEPENDENCIES=OFF \
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