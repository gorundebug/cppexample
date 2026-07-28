#!/usr/bin/env bash
set -euo pipefail

if (($# != 2)); then
  echo "usage: $0 <service-directory> <output-directory>" >&2
  exit 2
fi

service_dir="${1%/}"
output_dir="${2%/}"
service_name="$(basename "${service_dir}")"
overlay_dir=".servicegen/cpp-services/${service_name}"

if [[ ! -f "${service_dir}/CMakeLists.txt" ]]; then
  echo "C++ service directory does not contain CMakeLists.txt: ${service_dir}" >&2
  exit 1
fi
if [[ ! -d "${overlay_dir}" ]]; then
  echo "C++ service publishing overlay is missing: ${overlay_dir}" >&2
  exit 1
fi
if [[ -e "${output_dir}" && -n "$(find "${output_dir}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "output directory must be empty: ${output_dir}" >&2
  exit 1
fi

mkdir -p "${output_dir}"
cp -R "${service_dir}/." "${output_dir}/"

cp CMakePresets.json Dockerfile.cmake docker-compose.cmake.yml \
  .clang-format .clang-tidy .dockerignore .gitignore "${output_dir}/"

mkdir -p "${output_dir}/docker" "${output_dir}/tools" "${output_dir}/scripts"
cp -R docker/. "${output_dir}/docker/"
cp -R tools/userver "${output_dir}/tools/userver"
cp scripts/cmake-docker.sh scripts/build.sh scripts/test.sh \
  scripts/lint.sh scripts/format.generated.sh \
  scripts/configure-git-auth.generated.sh "${output_dir}/scripts/"

# Apply service-specific entrypoints last. Generated overlay source names make
# regeneration ownership explicit; published repositories receive conventional
# filenames.
cp "${overlay_dir}/Makefile" "${output_dir}/Makefile"
cp "${overlay_dir}/make.generated.mk" "${output_dir}/make.generated.mk"
cp "${overlay_dir}/docker-compose.generated.yml" \
  "${output_dir}/docker-compose.yml"
cp "${overlay_dir}/docker-compose.cmake.generated.yml" \
  "${output_dir}/docker-compose.cmake.yml"

echo "Packaged standalone C++ service ${service_name} in ${output_dir}"