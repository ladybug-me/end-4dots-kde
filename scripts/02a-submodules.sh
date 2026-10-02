#!/usr/bin/env bash
# Initializes and verifies git submodules required by the repository.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/submodules.sh"

BUNDLE_DIR="${BUNDLE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [[ -f "$BUNDLE_DIR/.gitmodules" ]]; then
    info "Initializing submodules..."
    prune_removed_submodules "$BUNDLE_DIR"
    git -C "$BUNDLE_DIR" submodule sync --recursive >/dev/null 2>&1 || true
    git -C "$BUNDLE_DIR" submodule update --init --recursive --depth 1 --jobs "$(nproc 2>/dev/null || echo 1)" >/dev/null 2>&1 || true

    while IFS=' ' read -r _ sub_path; do
        [[ -n "$sub_path" ]] || continue
        if ! submodule_has_content "$BUNDLE_DIR/$sub_path"; then
            info "$sub_path is empty; fetching it..."
            if ! ensure_submodule_content "$BUNDLE_DIR" "$sub_path"; then
                warn "Submodule $sub_path could not be fetched."
            else
                ok "Submodule $sub_path ready."
            fi
        else
            ok "Submodule $sub_path ready."
        fi
    done < <(git -C "$BUNDLE_DIR" config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null || true)
fi
