#!/usr/bin/env bash
# clone.generated.sh — clone services and modules that are listed in .gitignore.
# Run this after cloning the project to restore all dependencies.
#
# Usage: bash clone.generated.sh

set -euo pipefail

clone_if_missing() {
    local dir="$1"
    local repo="$2"
    local revision="$3"
    if [ -d "$dir" ]; then
        echo "  skip  $dir (already present)"
    else
        echo "  clone $repo@$revision → $dir"
        git clone --branch "$revision" --depth 1 "$repo" "$dir"
    fi
}

echo "==> Cloning services..."
clone_if_missing "inventoryservice" "https://github.com/gorundebug/cppexample-inventoryservice.git" "v0.0.1"
clone_if_missing "orderservice" "https://github.com/gorundebug/cppexample-orderservice.git" "v0.0.1"

echo "==> Cloning modules..."
clone_if_missing "inventory_service_api" "https://github.com/gorundebug/cppexample-inventory-service-api.git" "v0.0.1"
clone_if_missing "model" "https://github.com/gorundebug/cppexample-model.git" "v0.0.1"
clone_if_missing "order_service_api" "https://github.com/gorundebug/cppexample-order-service-api.git" "v0.0.1"

echo "==> Done."