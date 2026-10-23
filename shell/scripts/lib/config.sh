#!/usr/bin/env bash
# Helpers for updating the shell config file safely.

# Atomically replace a file with the JSON read from stdin.
#
# The content is written to a unique temporary file (instead of the shared
# "$file.tmp" the callers used before) and validated before the original is
# replaced. Concurrent invocations can no longer move a half-written temp over
# the config, which is how config.json used to end up empty.
config_json_replace() {
    local file="$1"
    [ -f "$file" ] || return 1

    local tmp
    tmp="$(mktemp "${file}.XXXXXX")" || return 1

    if cat > "$tmp" && jq empty "$tmp" >/dev/null 2>&1; then
        mv "$tmp" "$file"
    else
        rm -f "$tmp"
        return 1
    fi
}

# Apply a jq program to a JSON file and atomically write the result back.
#
# Usage: config_json_update <file> <jq args...>
# Example: config_json_update "$config" --arg v "$value" '.some.key = $v'
config_json_update() {
    local file="$1"
    shift
    [ -f "$file" ] || return 1

    local tmp
    tmp="$(mktemp "${file}.XXXXXX")" || return 1

    if jq "$@" "$file" > "$tmp" 2>/dev/null && jq empty "$tmp" >/dev/null 2>&1; then
        mv "$tmp" "$file"
    else
        rm -f "$tmp"
        return 1
    fi
}
