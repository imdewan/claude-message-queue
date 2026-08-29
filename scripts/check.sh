#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

"$repo_dir/tests/test-claude-queue.sh"

python3 -m json.tool "$repo_dir/.claude-plugin/plugin.json" >/dev/null
python3 -m json.tool "$repo_dir/.claude-plugin/marketplace.json" >/dev/null

if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$repo_dir"
  claude plugin validate "$repo_dir/skills"
else
  printf 'claude not installed; skipped plugin validation\n'
fi
