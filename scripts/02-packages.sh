#!/usr/bin/env bash
# 02-packages.sh — Install all packages: PKGBUILDs/RPMs + supplemental.
# Calls installDP.sh/installDP_fedora.sh for groups, then pkginstall.sh for extras.

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"

echo
echo "════════════════════════════════════════"
echo "  Step 2/9 — Packages"
echo "════════════════════════════════════════"

echo
if [[ "$BASE_DISTRO" == "arch" ]]; then
    echo "--- 2a: Installing from local PKGBUILDs (sdata/arch-dist) ---"
    bash "$BUNDLE_DIR/sdata/arch-dist/installDP.sh"
elif [[ "$BASE_DISTRO" == "fedora" ]]; then
    echo "--- 2a: Installing from local RPMs/groups (sdata/fedora-dist) ---"
    bash "$BUNDLE_DIR/sdata/fedora-dist/installDP_fedora.sh"
fi

echo
echo "--- 2b: Installing supplemental packages (fonts, cursors, Python) ---"
REPO_ROOT="$BUNDLE_DIR" bash "$BUNDLE_DIR/pkginstall.sh"

echo
echo "--- 2c: Installing MicroTeX (Manual Build) ---"
bash "$BUNDLE_DIR/scripts/install-microtex.sh"

if [[ "$BASE_DISTRO" == "fedora" ]]; then
    echo
    echo "--- 2d: Compatibility Symlinks ---"
    # Fix Arch -> Fedora compatibility for qdbus6
    if [ ! -L /usr/local/bin/qdbus6 ]; then
        sudo ln -s /usr/bin/qdbus-qt6 /usr/local/bin/qdbus6 2>/dev/null || true
    fi
fi

echo
echo "[OK]  Package installation complete."
