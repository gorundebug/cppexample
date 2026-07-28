#!/usr/bin/env bash
set -euo pipefail

exec docker compose -f docker-compose.cmake.yml run --build --rm cpp-build \
  /bin/bash -lc '
    cmake --preset docker-debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

    mapfile -d "" sources < <(
      find . -path ./build -prune -o -type f \
        \( -name "*.cpp" -o -name "*.hpp" -o -name "*.h" \) -print0
    )
    if ((${#sources[@]})); then
      clang-format --dry-run --Werror "${sources[@]}"
    fi

    mapfile -d "" translation_units < <(
      find . -path ./build -prune -o -type f -name "*.cpp" -print0
    )
    for source in "${translation_units[@]}"; do
      clang-tidy -p /workspace/build "$source"
    done
  '