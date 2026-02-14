#!/bin/bash

PYTHON_PLUGINS=()
LUA_PLUGINS=()

while IFS= read -r line; do
    submodule_path=$(echo "$line" | awk '{print $2}')

    if [[ -z "$submodule_path" ]]; then
        continue
    fi

    plugin_json="$submodule_path/plugin.json"
    plugin_name=$(basename "$submodule_path")

    if [[ -f "$plugin_json" ]]; then
        backend_type=$(jq -r '.backendType // "undefined"' "$plugin_json" 2>/dev/null)
        use_backend=$(jq -r 'if has("useBackend") then .useBackend else true end' "$plugin_json" 2>/dev/null)

        if [[ "$use_backend" == "false" || "$backend_type" == "lua" ]]; then
            LUA_PLUGINS+=("$plugin_name")
        else
            PYTHON_PLUGINS+=("$plugin_name")
        fi
    else
        echo "Warning: No plugin.json found in $submodule_path"
    fi
done < <(git submodule status)

# Check open PRs for Python plugins being ported to Lua
declare -A IN_PROGRESS_PLUGINS

if command -v curl &>/dev/null; then
    pr_data=$(curl -sf "https://api.github.com/repos/SteamClientHomebrew/PluginDatabase/pulls?state=open&per_page=100" 2>/dev/null)

    if [[ -n "$pr_data" ]]; then
        # Only consider PRs with [lua-port] in the title
        lua_port_prs=$(echo "$pr_data" | jq -r '.[] | select(.title | ascii_downcase | contains("[lua-port]")) | .number' 2>/dev/null)

        for pr_number in $lua_port_prs; do
            files_data=$(curl -sf "https://api.github.com/repos/SteamClientHomebrew/PluginDatabase/pulls/${pr_number}/files" 2>/dev/null)

            if [[ -n "$files_data" ]]; then
                changed_plugins=$(echo "$files_data" | jq -r '.[].filename' 2>/dev/null | grep '^plugins/' | sed 's|^plugins/||' | cut -d'/' -f1 | sort -u)

                for changed_plugin in $changed_plugins; do
                    for py_plugin in "${PYTHON_PLUGINS[@]}"; do
                        if [[ "$changed_plugin" == "$py_plugin" ]]; then
                            IN_PROGRESS_PLUGINS["$py_plugin"]=1
                        fi
                    done
                done
            fi
        done
    fi
fi

TOTAL_PLUGINS=$(( ${#LUA_PLUGINS[@]} + ${#PYTHON_PLUGINS[@]} ))

echo "## Repository Manifest"
echo ""

# Determine the max rows needed
max_rows=${#LUA_PLUGINS[@]}
if (( ${#PYTHON_PLUGINS[@]} > max_rows )); then
    max_rows=${#PYTHON_PLUGINS[@]}
fi

echo "The following table describes the remaining deprecated Python plugins that need to be ported to Lua."
echo "Python is no longer officially supported by Millennium and will be removed entirely in a future update."

echo ""
echo "**Total**: ${TOTAL_PLUGINS}"
echo " * **Lua**: ${#LUA_PLUGINS[@]}"
echo " * **Python**: ${#PYTHON_PLUGINS[@]}"
echo ""
echo ""

echo "| Lua | Python |"
echo "|-----|--------|"

for (( i=0; i<max_rows; i++ )); do
    if (( i < ${#LUA_PLUGINS[@]} )); then
        lua_num="$(( i + 1 ))"
        lua_name="${LUA_PLUGINS[$i]}"
    else
        lua_num=""
        lua_name=""
    fi

    if (( i < ${#PYTHON_PLUGINS[@]} )); then
        py_num="$(( i + 1 ))"
        py_name="${PYTHON_PLUGINS[$i]}"
        if [[ -n "${IN_PROGRESS_PLUGINS[$py_name]+x}" ]]; then
            py_name="$py_name (in-progress)"
        fi
    else
        py_num=""
        py_name=""
    fi

    echo "| $lua_name | $py_name |"
done
