#!/usr/bin/env bash
# merge.sh — merge a newly generated archive into the project.
#
# Rules:
#   ADD  — file is new (doesn't exist in project yet): always copied
#   UPD  — manifest marks an existing file as generated: overwritten
#   SKP  — manifest marks an existing file as user-owned: left untouched
#
# Usage: bash scripts/merge.sh <archive.zip|archive.tar.gz>
#        make merge ARCHIVE=/path/to/archive.zip

set -euo pipefail

ARCHIVE="${1:-}"
if [[ -z "$ARCHIVE" ]]; then
    echo "Usage: $0 <archive.zip|archive.tar.gz>" >&2
    exit 1
fi
if [[ ! -f "$ARCHIVE" ]]; then
    echo "Error: '$ARCHIVE' not found" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
TMP_DIR="$PROJECT_DIR/tmp/merge_$TIMESTAMP"

mkdir -p "$TMP_DIR"
echo "Unpacking '$ARCHIVE' → $TMP_DIR ..."

case "$ARCHIVE" in
    *.zip)
        unzip -q "$ARCHIVE" -d "$TMP_DIR"
        ;;
    *.tar.gz|*.tgz)
        tar -xzf "$ARCHIVE" -C "$TMP_DIR"
        ;;
    *)
        echo "Error: unsupported archive format (supported: .zip, .tar.gz)" >&2
        rm -rf "$TMP_DIR"
        exit 1
        ;;
esac

# The archive contains a single top-level directory (the project name).
# Strip it so paths are relative to the project root.
SRC_ROOT=""
for d in "$TMP_DIR"/*/; do
    if [[ -d "$d" ]]; then
        SRC_ROOT="$d"
        break
    fi
done
# Fallback: no subdirectory — use the tmp dir itself
if [[ -z "$SRC_ROOT" || ! -d "$SRC_ROOT" ]]; then
    SRC_ROOT="$TMP_DIR/"
fi

# Remove trailing slash for clean path arithmetic.
SRC_ROOT="${SRC_ROOT%/}"

MANIFEST="$SRC_ROOT/.servicegen/manifest.tsv"
if [[ ! -f "$MANIFEST" ]]; then
    echo "Error: archive does not contain .servicegen/manifest.tsv" >&2
    rm -rf "$TMP_DIR"
    exit 1
fi

ADDED=0
UPDATED=0
SKIPPED=0

echo ""
while IFS=$'\t' read -r ownership mode rel; do
    if [[ -z "$ownership" || "$ownership" == \#* ]]; then
        continue
    fi
    if [[ "$ownership" != "generated" && "$ownership" != "user-owned" ]]; then
        echo "Error: invalid ownership '$ownership' for '$rel'" >&2
        exit 1
    fi
    if [[ ! "$mode" =~ ^0[0-7]{3}$ ]]; then
        echo "Error: invalid mode '$mode' for '$rel'" >&2
        exit 1
    fi
    case "$rel" in
        ""|/*|..|../*|*/../*|*/..)
            echo "Error: unsafe manifest path '$rel'" >&2
            exit 1
            ;;
    esac

    src="$SRC_ROOT/$rel"
    dst="$PROJECT_DIR/$rel"
    if [[ ! -f "$src" ]]; then
        echo "Error: manifest file '$rel' is missing from archive" >&2
        exit 1
    fi

    if [[ ! -f "$dst" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        chmod "$mode" "$dst"
        echo "  ADD  $rel"
        ADDED=$((ADDED + 1))
    elif [[ "$ownership" == "generated" ]]; then
        cp "$src" "$dst"
        chmod "$mode" "$dst"
        echo "  UPD  $rel"
        UPDATED=$((UPDATED + 1))
    else
        echo "  SKP  $rel"
        SKIPPED=$((SKIPPED + 1))
    fi
done < "$MANIFEST"

echo ""
echo "Merge complete: ${ADDED} added, ${UPDATED} updated, ${SKIPPED} skipped."
echo "Removing tmp dir $TMP_DIR ..."
rm -rf "$TMP_DIR"
echo "Done."