#!/bin/bash

# Get a stable plugin ID from git history.
# Uses the first commit hash not authored by the template bot.
# Falls back to the root commit if all commits are from the bot.
#
# Usage:
#   source get-plugin-id.sh
#   id=$(get_plugin_id)              # current directory
#   id=$(get_plugin_id /path/to/repo) # specific repo

get_plugin_id() {
    local repo_path="${1:-.}"
    local plugin_id

    plugin_id=$(git -C "$repo_path" log --format='%H %ae' --reverse 2>/dev/null \
        | grep -Fv -e '81448108+shdwmtr@users.noreply.github.com' -e 'millennium[bot]@noreply.steambrew.app' \
        | head -1 | cut -d' ' -f1 | tr -d '\n')

    # Fallback to root commit if all commits are from the template bot
    [[ -z "$plugin_id" ]] && plugin_id=$(git -C "$repo_path" rev-list --max-parents=0 HEAD 2>/dev/null | tr -d '\n')

    echo "$plugin_id"
}
