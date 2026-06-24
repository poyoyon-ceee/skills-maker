#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/.cursor/skills"
DST="$HOME/.cursor/skills"

if [[ ! -d "$SRC" ]]; then
  echo "Skills source not found: $SRC" >&2
  exit 1
fi

mkdir -p "$DST"
cp -r "$SRC/"* "$DST/"

echo "Installed skills from $SRC to $DST"
echo "Restart Cursor if skills do not appear."
