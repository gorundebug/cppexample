#!/usr/bin/env bash
# clone.sh — clone services and modules that are listed in .gitignore.
# Run this after cloning the project to restore all dependencies.
#
# Usage: bash clone.sh

set -euo pipefail

clone_if_missing() {
    local dir="$1"
    local repo="$2"
    if [ -d "$dir" ]; then
        echo "  skip  $dir (already present)"
    else
        echo "  clone $repo → $dir"
        git clone "$repo" "$dir"
    fi
}

echo "==> Cloning services..."
clone_if_missing "inventoryservice" "https://github.com/gorundebug/cppexample-inventoryservice"
clone_if_missing "orderservice" "https://github.com/gorundebug/cppexample-orderservice"

echo "==> Cloning modules..."

echo "==> Done."