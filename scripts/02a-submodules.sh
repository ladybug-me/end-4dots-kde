#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/submodules.sh"

BUNDLE_DIR="${BUNDLE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [[ -f "$BUNDLE_DIR/.gitmodules" ]]; then
    info "Initializing submodules..."
    prune_removed_submodules "$BUNDLE_DIR"
    git -C "$BUNDLE_DIR" submodule sync --recursive >/dev/null 2>&1 || true
    git -C "$BUNDLE_DIR" submodule update --init --recursive --depth 1 --jobs "$(nproc 2>/dev/null || echo 1)" >/dev/null 2>&1 || true
fi

if ! submodule_has_content "$BUNDLE_DIR/shell/modules/common/widgets/shapes"; then
    info "shell/modules/common/widgets/shapes is empty; fetching it another way."
    if ! ensure_submodule_content "$BUNDLE_DIR" "shell/modules/common/widgets/shapes"; then
        err "shell/modules/common/widgets/shapes is still empty, and the installer cannot deploy without it."
        cat >&2 <<EOF

          Fetch it by hand:

            git -C "$BUNDLE_DIR" submodule update --init --recursive shell/modules/common/widgets/shapes

          Running this step on its own tries again:

            bash "$BUNDLE_DIR/scripts/02a-submodules.sh"

          A checkout that cannot be written to cannot fetch a submodule. If
          this one is the read-only shared folder, clone the repository to a
          writable directory first and install from there.
EOF
        exit 1
    fi
fi

ok "shell/modules/common/widgets/shapes ready."
