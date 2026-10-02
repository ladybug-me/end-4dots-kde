#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/lib/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/lib/privileges.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/lib/packages.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/lib/matugen.sh"

test_matugen_present_checks_path() {
    local tmp
    tmp="$(new_tmpdir)"
    mkdir -p "$tmp/bin"

    if (HOME="$tmp" PATH="$tmp/bin" matugen_present); then
        fail "matugen_present should return false when matugen is not on PATH"
    fi

    touch "$tmp/bin/matugen"
    chmod +x "$tmp/bin/matugen"

    if ! (HOME="$tmp" PATH="$tmp/bin" matugen_present); then
        fail "matugen_present should return true when matugen is on PATH"
    fi
}

test_cleanup_legacy_cargo_matugen_removes_binaries() {
    local tmp
    tmp="$(new_tmpdir)"
    mkdir -p "$tmp/.cargo/bin"

    touch "$tmp/.cargo/bin/matugen"

    (
        HOME="$tmp"
        caelestia_sudo() { "$@"; }
        export -f caelestia_sudo
        cleanup_legacy_cargo_matugen
    )

    assert_file_missing "$tmp/.cargo/bin/matugen" "cargo matugen should be removed"
}

test_ensure_matugen_reports_success_when_present() {
    local tmp
    tmp="$(new_tmpdir)"
    mkdir -p "$tmp/bin"
    touch "$tmp/bin/matugen"
    chmod +x "$tmp/bin/matugen"

    (
        HOME="$tmp"
        BASE_DISTRO=arch
        PATH="$tmp/bin"
        if ! ensure_matugen; then
            exit 1
        fi
    ) || fail "ensure_matugen should succeed when matugen is present on PATH"
}

test_install_matugen_github_downloads_and_installs() {
    local tmp
    tmp="$(new_tmpdir)"
    mkdir -p "$tmp/usr/local/bin" "$tmp/assets"

    touch "$tmp/assets/matugen"
    chmod +x "$tmp/assets/matugen"
    tar -czf "$tmp/assets/matugen-v4.2.0-x86_64.tar.gz" -C "$tmp/assets" matugen

    (
        HOME="$tmp"
        caelestia_sudo() {
            if [[ "$1" == "install" ]]; then
                cp "$4" "$tmp/usr/local/bin/matugen"
                return 0
            fi
            "$@"
        }
        export -f caelestia_sudo

        curl() {
            if [[ "$*" == *"releases/latest"* ]]; then
                printf '{"assets":[{"browser_download_url":"https://github.com/InioX/matugen/releases/download/v4.2.0/matugen-v4.2.0-x86_64.tar.gz"}]}'
                return 0
            else
                cat "$tmp/assets/matugen-v4.2.0-x86_64.tar.gz"
                return 0
            fi
        }
        export -f curl

        if ! install_matugen_github; then
            exit 1
        fi
    ) || fail "install_matugen_github should succeed when release asset exists"

    assert_file_exists "$tmp/usr/local/bin/matugen" "github release binary should be installed"
}

test_install_matugen_debian_falls_back_to_cargo() {
    local tmp
    tmp="$(new_tmpdir)"
    mkdir -p "$tmp/bin" "$tmp/.cargo/bin"

    (
        HOME="$tmp"
        caelestia_sudo() {
            if [[ "$1" == "cp" || "$1" == "install" ]]; then
                return 0
            fi
            "$@"
        }
        export -f caelestia_sudo
        cargo() {
            if [[ "$1" == "install" ]]; then
                touch "$tmp/.cargo/bin/matugen"
                chmod +x "$tmp/.cargo/bin/matugen"
                return 0
            fi
            return 1
        }
        export -f cargo

        curl() { return 1; }
        export -f curl

        if ! install_matugen_debian; then
            exit 1
        fi
    ) || fail "install_matugen_debian should succeed via cargo fallback"

    assert_file_exists "$tmp/.cargo/bin/matugen" "cargo should install matugen when github download fails"
}

test_install_matugen_fedora_uses_github_when_copr_fails() {
    local tmp
    tmp="$(new_tmpdir)"
    mkdir -p "$tmp/usr/local/bin" "$tmp/assets"

    touch "$tmp/assets/matugen"
    chmod +x "$tmp/assets/matugen"
    tar -czf "$tmp/assets/matugen-v4.2.0-x86_64.tar.gz" -C "$tmp/assets" matugen

    (
        HOME="$tmp"
        BASE_DISTRO="fedora"
        caelestia_sudo() {
            if [[ "$1" == "dnf" ]]; then
                return 1
            fi
            if [[ "$1" == "install" ]]; then
                cp "$4" "$tmp/usr/local/bin/matugen"
                return 0
            fi
            "$@"
        }
        export -f caelestia_sudo

        curl() {
            if [[ "$*" == *"releases/latest"* ]]; then
                printf '{"assets":[{"browser_download_url":"https://github.com/InioX/matugen/releases/download/v4.2.0/matugen-v4.2.0-x86_64.tar.gz"}]}'
                return 0
            else
                cat "$tmp/assets/matugen-v4.2.0-x86_64.tar.gz"
                return 0
            fi
        }
        export -f curl

        if ! install_matugen_fedora; then
            exit 1
        fi
    ) || fail "install_matugen_fedora should succeed via github release when COPR fails"

    assert_file_exists "$tmp/usr/local/bin/matugen" "github release binary should be installed on fedora when copr fails"
}

test_install_matugen_fedora_falls_back_to_cargo_when_copr_and_github_fail() {
    local tmp
    tmp="$(new_tmpdir)"
    mkdir -p "$tmp/bin" "$tmp/.cargo/bin"

    (
        HOME="$tmp"
        BASE_DISTRO="fedora"
        caelestia_sudo() {
            if [[ "$1" == "dnf" ]]; then
                return 1
            fi
            if [[ "$1" == "cp" || "$1" == "install" ]]; then
                return 0
            fi
            "$@"
        }
        export -f caelestia_sudo

        curl() { return 1; }
        export -f curl

        cargo() {
            if [[ "$1" == "install" ]]; then
                touch "$tmp/.cargo/bin/matugen"
                chmod +x "$tmp/.cargo/bin/matugen"
                return 0
            fi
            return 1
        }
        export -f cargo

        if ! install_matugen_fedora; then
            exit 1
        fi
    ) || fail "install_matugen_fedora should succeed via cargo fallback when COPR and GitHub fail"

    assert_file_exists "$tmp/.cargo/bin/matugen" "cargo should install matugen when fedora copr and github fail"
}

run_tests
