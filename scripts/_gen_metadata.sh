#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/build/get-plugin-id.sh"

parse_plugin() {
    local plugins_dir=$1
    local submodule=$2
    local submodule_path="$plugins_dir/$submodule"

    local plugin_name commit_id format plugin_slug
    plugin_name=$(get_plugin_id "$submodule_path")
    commit_id=$(git -C "$submodule_path" rev-parse HEAD 2>/dev/null | tr -d '\n')

    if [[ -f "$submodule_path/millennium.toml" ]]; then
        format="star"
        plugin_slug=$(grep -A5 '^\[plugin\]' "$submodule_path/millennium.toml" | grep '^id' | head -1 | sed -E 's/^id[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/')
    else
        format="loose"
        plugin_slug=""
    fi

    jq -cn --arg id "$plugin_name" --arg commitId "$commit_id" --arg format "$format" --arg pluginId "$plugin_slug" \
        'if $format == "star" then {id: $id, commitId: $commitId, format: $format, pluginId: $pluginId} else {id: $id, commitId: $commitId, format: $format} end'
}

plugins_dir="$(pwd)/plugins"

if [[ -d "$plugins_dir" ]]; then
    while IFS= read -r submodule; do
        parse_plugin "$plugins_dir" "$submodule"
    done < <(ls "$plugins_dir")
fi | jq -s '.' > metadata.json
