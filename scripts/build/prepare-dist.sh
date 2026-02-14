#!/bin/bash

# Prepare Distribution Files
# This script prepares the distribution files for the plugin

# Parse command line arguments
SILENT=false
for arg in "$@"; do
  case $arg in
    --silent)
      SILENT=true
      shift
      ;;
    *)
      # Unknown option or positional argument
      ;;
  esac
done

# Function to log messages with appropriate level
log_message() {
  local level="$1"
  local message="$2"

  if [ "$SILENT" = true ] && [[ "$level" = "warning" || "$level" = "notice" ]]; then
    level="debug"
  fi

  echo "::$level::$message"
}

mkdir -p dist

cp -r ".millennium" dist/.millennium 2>/dev/null || { log_message "error" ".millennium directory not found, it is required to run the plugin."; exit 1; }
cp "plugin.json" dist/plugin.json 2>/dev/null || { log_message "error" "plugin.json was not found. It is required for plugins to have."; exit 1; }
cp "requirements.txt" dist/requirements.txt 2>/dev/null || log_message "warning" "requirements.txt not found, skipping."
cp "PLUGIN.md" dist/README.md 2>/dev/null || cp "README.md" dist/README.md 2>/dev/null || cp "README" dist/README 2>/dev/null || log_message "warning" "README.md or PLUGIN.md not found, skipping."

BACKEND_DIR=$(jq -r '.backend' plugin.json)
if [ "$BACKEND_DIR" != "null" ]; then
  cp -r "$BACKEND_DIR" ./dist/"$BACKEND_DIR"
else
  cp -r "backend" ./dist/backend 2>/dev/null || log_message "warning" "backend directory not found, skipping."
fi

include=$(jq -r '.include // [] | .[]' plugin.json)

if [ -z "$include" ]; then
  log_message "notice" "No additional files to include."
else
  log_message "notice" "Including additional files: $include"
  for item in $include; do
    mkdir -p "./dist/$(dirname "$item")"
    cp -r "./$item" "./dist/$item"
  done
fi

log_message "notice" "Computing plugin metadata..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/get-plugin-id.sh"
echo "{\"commit\": \"$(git rev-parse HEAD)\", \"id\": \"$(get_plugin_id)\"}" > dist/metadata.json

PLUGIN_NAME=$(jq -r '.name' plugin.json) || { log_message "error" "name not found in plugin.json"; exit 1; }
echo "PLUGIN_NAME=$PLUGIN_NAME" >> $GITHUB_ENV

mkdir -p dist/"$PLUGIN_NAME"
mv dist/{*,.*} dist/"$PLUGIN_NAME" 2>/dev/null

log_message "notice" "Successfully built plugin."
