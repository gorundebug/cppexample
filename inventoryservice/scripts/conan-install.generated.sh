#!/usr/bin/env bash
set -euo pipefail

project_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
framework_dir="${SERVICELIB_SOURCE_DIR:-/opt/servicelib}"
build_type="${1:-Release}"
output_dir="${2:-$project_dir/build/conan-${build_type,,}}"

if [[ ! -x "$framework_dir/scripts/conan-install.sh" ]]; then
  echo "cppservicelib Conan entrypoint is missing: $framework_dir/scripts/conan-install.sh" >&2
  exit 2
fi

export CPPSERVICELIB_ENABLE_CRON=False

"$framework_dir/scripts/conan-install.sh" "$build_type" "$output_dir" \
  "${@:3}"

toolchain="$output_dir/conan_toolchain.cmake"
if [[ ! -f "$toolchain" ]]; then
  echo "Conan toolchain is missing: $toolchain" >&2
  exit 2
fi
printf '%s\n' "$toolchain" > "$output_dir/toolchain.path"