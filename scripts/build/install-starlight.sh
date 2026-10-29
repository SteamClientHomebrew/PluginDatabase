#!/bin/bash
set -euo pipefail

# npm 1.1.6 predates source-commit metadata and the sign command.
# Keep PR builds and production signing on the same immutable compiler source.
cargo install starlight --locked \
  --git https://github.com/SteamClientHomebrew/Millennium.git \
  --rev d6a7822a43744b6290a0e059bdd032d9b9a2ec94 \
  --root "$RUNNER_TEMP/starlight"

echo "$RUNNER_TEMP/starlight/bin" >> "$GITHUB_PATH"
