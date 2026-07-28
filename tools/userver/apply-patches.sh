#!/usr/bin/env bash
set -euo pipefail

if (($# != 1)); then
  echo "usage: $0 <userver-source-dir>" >&2
  exit 2
fi

userver_dir=$1
patch_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/patches" && pwd)

if [[ ! -d "$userver_dir" ]]; then
  echo "userver source directory does not exist: $userver_dir" >&2
  exit 2
fi

for patch_file in "$patch_dir"/*.patch; do
  normalized_patch=$(mktemp)
  trap 'rm -f "$normalized_patch"' EXIT
  {
    cat "$patch_file"
    printf '\n'
  } >"$normalized_patch"

  if git -C "$userver_dir" apply --reverse --check "$normalized_patch" \
      >/dev/null 2>&1; then
    echo "userver patch already applied: $(basename "$patch_file")"
    rm -f "$normalized_patch"
    trap - EXIT
    continue
  fi

  if ! git -C "$userver_dir" apply --check "$normalized_patch"; then
    echo "userver patch is incompatible with the pinned source: $patch_file" \
      >&2
    exit 1
  fi

  git -C "$userver_dir" apply "$normalized_patch"
  echo "applied userver patch: $(basename "$patch_file")"
  rm -f "$normalized_patch"
  trap - EXIT
done