#!/bin/bash
submodules=()

while read -r line; do
    sha=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')

    if [[ "${APPLY_FILTER:-false}" == "true" ]] && ! grep -qxF "$name" <<< "${CHANGED_PLUGINS:-}"; then
        continue
    fi

    url=$(git config --get submodule."$name".url)
    if [[ -n "$url" ]]; then
        owner=$(echo "$url" | sed -E 's|https://github.com/([^/]+)/.*|\1|')
        repo=$(echo "$url" | sed -E 's|https://github.com/[^/]+/([^/]+).*|\1|' | sed 's/.git$//')
        
        submodules+=("{\"repository\": \"$owner/$repo\", \"sha\": \"$sha\"}")
    fi
done < <(git submodule)

jq -cn --argjson submodules "[$(IFS=,; echo "${submodules[*]}")]" '{submodules: $submodules}'
