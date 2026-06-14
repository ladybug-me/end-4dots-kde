#!/usr/bin/env bash
# 02-packages.sh — Install all packages: PKGBUILDs + supplemental.
# Calls installDP.sh for local PKGBUILDs, then pkginstall.sh for extras.

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"

echo
echo "════════════════════════════════════════"
echo "  Step 2/9 — Package Installation"
echo "════════════════════════════════════════"

echo
echo "--- 2a: Installing from local PKGBUILDs (sdata/arch-dist) ---"
bash "$BUNDLE_DIR/sdata/arch-dist/installDP.sh"

echo
echo "--- 2b: Installing supplemental packages (fonts, cursors, Python) ---"
REPO_ROOT="$BUNDLE_DIR" bash "$BUNDLE_DIR/pkginstall.sh"

echo
echo "--- 2c: Installing MicroTeX (Manual Build) ---"
bash "$BUNDLE_DIR/scripts/install-microtex.sh"

echo
echo "[OK]  Package installation complete."
