#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/build/get-plugin-id.sh"

parse_plugin() {
    local plugins_dir=$1
    local submodule=$2
    local submodule_path="$plugins_dir/$submodule"

    local plugin_name commit_id
    plugin_name=$(get_plugin_id "$submodule_path")
    commit_id=$(git -C "$submodule_path" rev-parse HEAD 2>/dev/null | tr -d '\n')

    echo "{\"id\": \"$plugin_name\", \"commitId\": \"$commit_id\"}"
}

plugins_dir="$(pwd)/plugins"

if [[ -d "$plugins_dir" ]]; then
    while IFS= read -r submodule; do
        parse_plugin "$plugins_dir" "$submodule"
    done < <(ls "$plugins_dir")
fi | jq -s '.' > metadata.json
