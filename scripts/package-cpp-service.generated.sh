#!/usr/bin/env bash
set -euo pipefail

if (($# != 2)); then
  echo "usage: $0 <service-directory> <output-directory>" >&2
  exit 2
fi

service_dir="${1%/}"
output_dir="${2%/}"
service_name="$(basename "${service_dir}")"

if [[ ! -f "${service_dir}/CMakeLists.txt" ]]; then
  echo "C++ service directory does not contain CMakeLists.txt: ${service_dir}" >&2
  exit 1
fi
for file in Makefile make.generated.mk docker-compose.generated.yml \
  docker-compose.cmake.generated.yml; do
  if [[ ! -f "${service_dir}/${file}" ]]; then
    echo "C++ service publishing file is missing: ${service_dir}/${file}" >&2
    exit 1
  fi
done
if [[ -e "${output_dir}" && -n "$(find "${output_dir}" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "output directory must be empty: ${output_dir}" >&2
  exit 1
fi

mkdir -p "${output_dir}"
cp -R "${service_dir}/." "${output_dir}/"

cp CMakePresets.json Dockerfile.cmake docker-compose.cmake.yml \
  .clang-format .clang-tidy .dockerignore .gitignore "${output_dir}/"

mkdir -p "${output_dir}/docker" "${output_dir}/scripts"
cp -R docker/. "${output_dir}/docker/"
cp scripts/cmake-docker.generated.sh scripts/build.generated.sh scripts/test.generated.sh \
  scripts/lint.generated.sh scripts/format.generated.sh \
  scripts/configure-git-auth.generated.sh "${output_dir}/scripts/"

# Generated source names make replacement explicit inside the
# workspace; a published repository receives conventional Compose filenames.
cp "${service_dir}/docker-compose.generated.yml" \
  "${output_dir}/docker-compose.yml"
cp "${service_dir}/docker-compose.cmake.generated.yml" \
  "${output_dir}/docker-compose.cmake.yml"
rm -f "${output_dir}/docker-compose.generated.yml" \
  "${output_dir}/docker-compose.cmake.generated.yml"

echo "Packaged standalone C++ service ${service_name} in ${output_dir}"
