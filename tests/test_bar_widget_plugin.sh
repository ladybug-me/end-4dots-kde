#!/usr/bin/env bash
# Verifies the plugin-facing bar widget API: the registry singleton, its merge
# into BarWidgets, the bar delegate fallback, the editor merge and the manifest
# normalisation.

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$REPO_ROOT/shell/services/BarWidgetRegistry.qml"
BAR_WIDGETS="$REPO_ROOT/shell/modules/bar/BarWidgets.qml"
BAR="$REPO_ROOT/shell/modules/bar/Bar.qml"
CONTENT="$REPO_ROOT/shell/modules/bar/popouts/Content.qml"
EDITOR="$REPO_ROOT/shell/modules/nexus/pages/panels/taskbar/BarComponents.qml"
LOADER="$REPO_ROOT/shell/services/PluginLoader.qml"
DOCS="$REPO_ROOT/shell/modules/plugins/README.md"

if [[ ! -f "$REGISTRY" ]]; then
    skip_test "BarWidgetRegistry.qml not present in this flavor"
    exit 0
fi

test_the_registry_is_a_services_singleton() {
    assert_file_exists "$REGISTRY" "the plugin bar widget registry has to exist"
    assert_file_contains "$REGISTRY" 'pragma Singleton' "the registry has to be a singleton"
    assert_file_contains "$REGISTRY" 'function register(' "plugins register through register()"
    assert_file_contains "$REGISTRY" 'function unregister(' "and drop out through unregister()"
    assert_file_contains "$REGISTRY" 'function clear()' "a full reload clears the registry"
}

test_the_bar_widget_list_merges_the_plugin_registry() {
    assert_file_contains "$BAR_WIDGETS" 'BarWidgetRegistry.widgets' \
        "the widget registry has to fold in the plugins' widgets"
    assert_file_contains "$BAR_WIDGETS" 'allWidgets' \
        "built-ins and plugin widgets are combined into one list"
    # The merge must not leak into the helpers the node harness re-implements.
    assert_file_contains "$BAR_WIDGETS" 'return root.byId[id] !== undefined' \
        "isKnown reads the merged map so the harness keeps working"
}

test_the_bar_falls_back_to_plugin_widgets() {
    assert_file_contains "$BAR" 'BarWidgetRegistry.widget(id)?.componentUrl' \
        "the delegate chooser needs a fallback that resolves plugin components"
    assert_file_contains "$BAR" 'typeof item.handleHover === "function"' \
        "any widget can opt into hover popouts through handleHover"
}

test_the_bar_forwards_scroll_events_to_widgets() {
    assert_file_contains "$BAR" 'typeof item.handleWheel === "function"' \
        "any widget can opt into scroll handling through handleWheel"
    assert_file_contains "$BAR" 'item.handleWheel(pos -' \
        "the scroll hook is handed the position along the bar"
}

test_the_bar_hands_plugin_widgets_its_context() {
    assert_file_contains "$BAR" 'function applyWidgetContext(widget: var): void' \
        "the bar fills in the ambient values a plugin widget declares"
    assert_file_contains "$BAR" 'root.applyWidgetContext(item)' \
        "the context is handed over when the plugin component loads"
    assert_file_contains "$BAR" 'widget.hasOwnProperty(name)' \
        "only the values the widget declares are filled in"
    assert_file_contains "$DOCS" '`visibilities`' \
        "the ambient values a widget can ask for are documented"
}

test_a_widget_can_declare_a_sliding_popout() {
    assert_file_contains "$REGISTRY" 'popoutUrl' \
        "the registry keeps the popout path a widget declares"
    assert_file_contains "$CONTENT" 'import qs.services as QsServices' \
        "the services module is aliased so it cannot shadow the popout components"
    assert_file_contains "$CONTENT" 'QsServices.BarWidgetRegistry.widgets.filter(widget => widget.popoutUrl)' \
        "the popout container builds one popout per widget that declares one"
    assert_file_contains "$CONTENT" 'source: modelData.popoutUrl' \
        "a plugin popout is loaded from the path its manifest declares"
    assert_file_contains "$DOCS" '`popout`' \
        "the popout field is documented"
}

test_the_editor_labels_plugin_widgets() {
    assert_file_contains "$EDITOR" 'for (const widget of BarWidgetRegistry.widgets)' \
        "the toggle editor has to label every registered widget"
    assert_file_contains "$EDITOR" 'if (!BarWidgets.isKnown(entry.id)) continue;' \
        "entries left behind by a removed plugin must not linger in the editor"
}

test_the_loader_registers_and_unregisters_widgets() {
    assert_file_contains "$LOADER" 'function normalizeBarWidgets(meta): void' \
        "the manifest field has to be normalised before use"
    assert_file_contains "$LOADER" 'BarWidgetRegistry.register(' "enabling a plugin registers its widgets"
    assert_file_contains "$LOADER" 'BarWidgetRegistry.unregister(' "disabling a plugin drops its widgets"
    assert_file_contains "$LOADER" 'BarWidgetRegistry.clear()' "a full reload starts from an empty registry"
}

test_the_manifest_field_is_documented() {
    assert_file_contains "$DOCS" '"barWidgets"' "the manifest field has to be documented"
    assert_file_contains "$DOCS" 'component' "including the relative component path rule"
}

test_normalize_bar_widgets_rejects_escapes_and_applies_defaults() {
    if ! command -v node >/dev/null 2>&1; then
        skip_test "node is not available"
        return 0
    fi

    local harness
    harness="$(mktemp "${TMPDIR:-/tmp}/caelestia-barplugin.XXXXXX.mjs")"
    cat > "$harness" <<'EOF'
import { readFileSync } from "node:fs";

const src = readFileSync(process.argv[2], "utf8");

function sliceBalanced(from, open, close) {
    let depth = 0;
    for (let i = from; i < src.length; i++) {
        if (src[i] === open) depth++;
        else if (src[i] === close && --depth === 0) return src.slice(from, i + 1);
    }
    throw new Error("unbalanced " + open);
}

function stripTypes(header) {
    return header
        .replace(/\)\s*:\s*[A-Za-z_][\w<>.\[\]|]*\s*$/, ") ")
        .replace(/([(,\s])([A-Za-z_]\w*)\s*:\s*[A-Za-z_][\w<>.\[\]|]*/g, "$1$2");
}

function extractFunction(name) {
    const marker = "function " + name + "(";
    const start = src.indexOf(marker);
    if (start === -1) throw new Error(name + " not found");
    const text = sliceBalanced(start, "{", "}");
    const brace = text.indexOf("{");
    return stripTypes(text.slice(0, brace)) + text.slice(brace);
}

const normalize = new Function("meta", extractFunction("normalizeBarWidgets") + "\nreturn normalizeBarWidgets(meta);");

const eq = (actual, expected, msg) => {
    if (JSON.stringify(actual) !== JSON.stringify(expected)) {
        console.error("FAIL:", msg);
        console.error("  actual:  ", JSON.stringify(actual));
        console.error("  expected:", JSON.stringify(expected));
        process.exit(1);
    }
};

let meta = { id: "p", path: "/plugins/p", barWidgets: [
    { id: "w1", component: "Bar.qml" },
    { id: "w2", name: "Two", icon: "star", defaultZone: "left", component: "sub/W.qml", unavailableText: "nope" },
    { id: "w3", component: "W.qml", popout: "Popout.qml" }
] };
normalize(meta);
eq(meta.barWidgets, [
    { id: "w1", name: "w1", icon: "widgets", defaultZone: "right", available: true, unavailableText: "", componentUrl: "file:///plugins/p/Bar.qml", popoutUrl: "" },
    { id: "w2", name: "Two", icon: "star", defaultZone: "left", available: true, unavailableText: "nope", componentUrl: "file:///plugins/p/sub/W.qml", popoutUrl: "" },
    { id: "w3", name: "w3", icon: "widgets", defaultZone: "right", available: true, unavailableText: "", componentUrl: "file:///plugins/p/W.qml", popoutUrl: "file:///plugins/p/Popout.qml" }
], "a well-formed manifest is completed with defaults");

meta = { id: "p", path: "/plugins/p", barWidgets: [
    { id: "a", component: "/etc/passwd" },
    { id: "b", component: "../evil.qml" },
    { id: "c" },
    { component: "NoId.qml" },
    { id: "d", component: "ok.qml" },
    { id: "e", component: "ok2.qml", popout: "../evil.qml" },
    { id: "f", component: "ok3.qml", popout: "/etc/passwd" }
] };
normalize(meta);
eq(meta.barWidgets.map(w => w.id), ["d", "e", "f"], "absolute paths, parent escapes and incomplete specs are dropped");
eq(meta.barWidgets.map(w => w.popoutUrl), ["", "", ""], "a popout that escapes the plugin folder is dropped while the widget survives");

meta = { id: "p", path: "/plugins/p" };
normalize(meta);
eq(meta.barWidgets, [], "a plugin without widgets normalises to an empty list");

meta = { id: "p", path: "/plugins/p", barWidgets: [] };
normalize(meta);
eq(meta.barWidgets, [], "an empty list stays empty");

console.log("bar widget plugin manifest: all harness cases passed");
EOF

    if ! timeout 15 node "$harness" "$LOADER"; then
        rm -f "$harness"
        fail "the bar widget manifest harness failed"
        return 0
    fi
    rm -f "$harness"
}

run_tests
