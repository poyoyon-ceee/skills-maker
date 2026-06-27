#!/usr/bin/env bash
# Install all global Cursor skills + Superpowers session hook from this package folder.
set -euo pipefail

PACKAGE_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DST="$HOME/.cursor/skills"
HOOKS_DST="$HOME/.cursor/hooks"
HOOKS_CONFIG="$HOME/.cursor/hooks.json"
HOOKS_SRC="$PACKAGE_ROOT/_hooks"

mkdir -p "$SKILLS_DST"

for dir in "$PACKAGE_ROOT"/*/; do
  name="$(basename "$dir")"
  if [[ "$name" == "_hooks" ]]; then
    continue
  fi
  cp -r "$dir" "$SKILLS_DST/$name"
  echo "Skill: $name -> $SKILLS_DST/$name"
done

mkdir -p "$HOOKS_DST"
cp "$HOOKS_SRC/session-start" "$HOOKS_DST/session-start"
chmod +x "$HOOKS_DST/session-start"
echo "Hook: session-start -> $HOOKS_DST"

if [[ -f "$HOOKS_CONFIG" ]]; then
  echo ""
  echo "hooks.json already exists at $HOOKS_CONFIG"
  echo "Add under hooks.sessionStart if missing:"
  echo '  { "command": "./hooks/session-start" }'
else
  cat > "$HOOKS_CONFIG" <<'EOF'
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "./hooks/session-start"
      }
    ]
  }
}
EOF
fi

echo ""
echo "Done. Restart Cursor, then check Customize -> Skills and Hooks."
echo "See INSTALL.md in this folder for details."
