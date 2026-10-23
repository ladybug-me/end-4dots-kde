#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CMAKE_FILE="$ROOT/shell/CMakeLists.txt"
FETCH_SCRIPT="$ROOT/scripts/fetch-dependencies.sh"
REVISION_FILE="$ROOT/scripts/m3shapes-revision"
MAKEFILE="$ROOT/Makefile"

test_the_dependency_revision_is_pinned() {
    assert_file_contains "$CMAKE_FILE" \
        'set(_M3SHAPES_REVISION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../scripts/m3shapes-revision")' \
        "CMake must locate the M3Shapes revision manifest"
    assert_file_contains "$CMAKE_FILE" 'file(STRINGS "${_M3SHAPES_REVISION_FILE}" M3SHAPES_REV' \
        "CMake must read the M3Shapes revision manifest"
    assert_file_matches "$REVISION_FILE" '^[0-9a-f]{40}$' \
        "the M3Shapes revision manifest must contain one commit"
    assert_file_contains "$FETCH_SCRIPT" 'm3shapes-revision' \
        "the fetch command must read the revision manifest"
}

test_the_build_has_an_offline_path() {
    assert_file_contains "$CMAKE_FILE" 'option(CAELESTIA_OFFLINE "Disallow downloading build dependencies" OFF)' \
        "CMake must expose an offline build mode"
    assert_file_contains "$CMAKE_FILE" 'CAELESTIA_M3SHAPES_SOURCE_DIR' \
        "CMake must accept a pre-fetched dependency directory"
    assert_file_contains "$CMAKE_FILE" 'Offline build requested' \
        "offline configure must fail when the dependency is absent"
    assert_file_contains "$MAKEFILE" 'fetch-dependencies:' \
        "make must expose the dependency-fetch command"
}

run_tests
