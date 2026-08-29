#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_dir="$(cd "$script_dir/.." && pwd -P)"
install_dir="${CLAUDE_QUEUE_INSTALL_DIR:-$HOME/.local/bin}"
target="$install_dir/claude-queue"

mkdir -p "$install_dir"
cp "$repo_dir/bin/claude-queue" "$target"
chmod 0755 "$target"

printf 'Installed %s\n' "$target"
case ":$PATH:" in
  *":$install_dir:"*) ;;
  *) printf 'Add %s to PATH to run claude-queue from any terminal.\n' "$install_dir" ;;
esac
