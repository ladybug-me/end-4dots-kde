#!/usr/bin/env bash
set -uo pipefail

source "$(dirname "$0")/helpers.sh"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVICES="$REPO_ROOT/shell/plugin/src/Caelestia/Services"

# "<signature>|<source file>|<filename>" for each persisted Caelestia file. The
# signature locates the function that builds the path; the filename must survive.
persisted_paths=(
    "QString stolenShortcutsPath()|globalshortcut.cpp|stolen-shortcuts.json"
    "QString stolenEdgesPath()|screenedges.cpp|stolen-screen-edges.json"
    "QString KeybindsModel::keybindsPath() const|keybindsmodel.cpp|keybinds.json"
)

path_function() {
    sed -n "/$1/,/^}/p" "$SERVICES/$2"
}

test_persisted_paths_come_from_the_config_layer() {
    local spec signature file function
    for spec in "${persisted_paths[@]}"; do
        IFS='|' read -r signature file _ <<< "$spec"
        function="$(path_function "$signature" "$file")"
        assert_contains "$function" 'config::' \
            "$file must take its path from the config layer, which is what honors XDG_CONFIG_HOME"
        assert_not_contains "$function" 'QStandardPaths::' \
            "$file must not resolve the config root next to the path it builds"
        assert_not_contains "$function" 'QDir::homePath()' \
            "$file must not hard-code the home directory"
        assert_not_contains "$function" '/.config' \
            "$file must not name the default config root"
    done
}

test_each_path_keeps_its_existing_filename() {
    local spec signature file name function
    for spec in "${persisted_paths[@]}"; do
        IFS='|' read -r signature file name <<< "$spec"
        function="$(path_function "$signature" "$file")"
        assert_contains "$function" "\"$name\"" "$file must keep writing $name"
    done
}

run_tests
