#!/usr/bin/env bash
set -euo pipefail

src="${BASH_SOURCE[0]}"
while [ -L "$src" ]; do
  link_target="$(readlink "$src")"
  case "$link_target" in
    /*) src="$link_target" ;;
    *) src="$(dirname "$src")/$link_target" ;;
  esac
done
SCRIPT_DIR="$(cd "$(dirname "$src")" && pwd)"

if ! command -v node >/dev/null 2>&1; then
  echo "error: node is required but not found in PATH" >&2
  exit 1
fi

exec node "${SCRIPT_DIR}/apply.js" "$@"
