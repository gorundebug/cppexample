#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/dependency-proxy-env.generated.sh"

sanitizer="${1:?expected asan or tsan}"
action="${2:-test}"
case "$sanitizer" in
  asan)
    # Conan's CMake helper executes configure arguments through a shell. Keep
    # the CMake list separator inside the single -D argument instead of letting
    # the shell interpret it as a command separator.
    conan_configure_args='["-DUSERVER_FEATURE_CHAOTIC_EXPERIMENTAL=ON", "-DUSERVER_SANITIZE=addr\\;ub"]'
    cmake_options=(
      -DENABLE_ASAN=ON
      -DENABLE_UBSAN=ON
    )
    ;;
  tsan)
    conan_configure_args='["-DUSERVER_FEATURE_CHAOTIC_EXPERIMENTAL=ON", "-DUSERVER_FEATURE_UBOOST_CORO=ON", "-DUSERVER_SANITIZE=thread"]'
    cmake_options=(
      -DENABLE_TSAN=ON
    )
    ;;
  *)
    echo "unsupported sanitizer: $sanitizer" >&2
    exit 2
    ;;
esac

options="${cmake_options[*]}"
run_build() {
docker compose -f docker-compose.cmake.generated.yml run --build --rm \
  -e CPP_SANITIZER="$sanitizer" \
  -e CPP_CONAN_CONFIGURE_ARGS="$conan_configure_args" \
  -e SANITIZER_INTEGRATION="${SANITIZER_INTEGRATION:-1}" \
  -e SANITIZER_RUN_TESTS="${SANITIZER_RUN_TESTS:-1}" \
  -e CPP_SANITIZER_OPTIONS="$options" cpp-build \
  /bin/bash -lc \
  'set -euo pipefail
   source scripts/configure-git-auth.generated.sh
   build_dir="/workspace/build/sanitizers/$CPP_SANITIZER"
   conan_dir="/workspace/build/conan-sanitizer-$CPP_SANITIZER-clang"
   conan_extra_args=(
     -c:h "userver/*:tools.cmake:configure_args=$CPP_CONAN_CONFIGURE_ARGS"
     -c:h "userver/*:user.userver:sanitizer=$CPP_SANITIZER"
   )
   if [[ "$CPP_SANITIZER" == "tsan" ]]; then
     ignorelist_hash="$(sha256sum docker/userver-tsan-ignorelist.generated.txt | cut -d " " -f 1)"
     conan_extra_args+=(
       -s:h "librdkafka/*:compiler.sanitizer=Thread"
       -c:h "userver/*:user.userver:tsan_ignorelist=$ignorelist_hash"
       -c:h "userver/*:tools.info.package_id:confs=[\"user.userver:chaotic_openapi\",\"user.userver:sanitizer\",\"user.userver:tsan_ignorelist\"]"
       -c:h "userver/*:tools.build:cxxflags=[\"-fsanitize-ignorelist=/opt/userver/cmake/sanitize.blacklist.txt\",\"-fsanitize-ignorelist=/workspace/source/docker/userver-tsan-ignorelist.generated.txt\"]"
     )
   fi
   ./scripts/conan-install.generated.sh Release "$conan_dir" \
     -s:b build_type=Release \
     -s:h compiler=clang \
     -s:h compiler.version=18 \
     -s:h compiler.cppstd=20 \
     -s:h compiler.libcxx=libstdc++11 \
     -c:h "tools.build:compiler_executables={\"c\":\"clang\",\"cpp\":\"clang++\"}" \
     -o "userver/*:with_jemalloc=False" \
     -o "userver/*:with_phdr_cache=False" \
     "${conan_extra_args[@]}"
   conan_toolchain="$(cat "$conan_dir/toolchain.path")"
   cmake -S . -B "$build_dir" -G Ninja \
     --fresh \
     -DCMAKE_BUILD_TYPE=Release \
     -DCMAKE_TOOLCHAIN_FILE="$conan_toolchain" \
     -DMODULES_ROOT=/workspace/source \
     -DSERVICELIB_SOURCE_DIR="$SERVICELIB_SOURCE_DIR" \
     -DFETCH_CPP_DEPENDENCIES=OFF \
     $CPP_SANITIZER_OPTIONS
   cmake --build "$build_dir" --parallel
   if [[ "$SANITIZER_RUN_TESTS" == "1" ]]; then case "$CPP_SANITIZER" in
     asan)
       ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 \
       UBSAN_OPTIONS=halt_on_error=1 \
         ctest --test-dir "$build_dir" --output-on-failure
       ;;
     tsan)
       TSAN_OPTIONS="halt_on_error=1:ignore_interceptors_accesses=1:suppressions=/opt/userver/cmake/tsan.suppressions.txt:allow_addr2line=1:external_symbolizer_path=/usr/bin/addr2line" \
         ctest --test-dir "$build_dir" --output-on-failure
       ;;
   esac; fi
   if [[ "$SANITIZER_INTEGRATION" == "1" ]]; then
     scripts/sanitizer-integration.generated.sh \
       "$build_dir" "$CPP_SANITIZER"
   fi'
}



case "$action" in
  build)
    SANITIZER_RUN_TESTS=0 SANITIZER_INTEGRATION=0 run_build
    ;;
  test)
    run_build
    ;;
  *)
    echo "unsupported sanitizer action: $action" >&2
    exit 2
    ;;
esac