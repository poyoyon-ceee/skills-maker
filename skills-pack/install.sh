#!/usr/bin/env bash
# Install global Cursor skills from skills-pack with duplicate-safe merge.
set -euo pipefail

PACKAGE_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DST="$HOME/.cursor/skills"
HOOKS_DST="$HOME/.cursor/hooks"
HOOKS_CONFIG="$HOME/.cursor/hooks.json"
HOOKS_SRC="$PACKAGE_ROOT/_hooks"

mkdir -p "$SKILLS_DST"

get_skill_name() {
  local file="$1"
  awk '/^name:/ { sub(/^name:[[:space:]]*/, ""); print; exit }' "$file"
}

declare -A CANONICAL
while IFS= read -r skill; do
  rel="${skill#"$PACKAGE_ROOT"/}"
  name="$(get_skill_name "$skill")"
  [[ -n "$name" ]] && CANONICAL["$name"]="$rel"
done < <(find "$PACKAGE_ROOT" -name SKILL.md -type f | sort)

echo "=== skills-pack install ==="
echo "Package skills: ${#CANONICAL[@]}"
echo ""

for dir in "$PACKAGE_ROOT"/*/; do
  name="$(basename "$dir")"
  [[ "$name" == "_hooks" ]] && continue

  while IFS= read -r skill; do
    rel="${skill#"$PACKAGE_ROOT"/}"
    dest="$SKILLS_DST/$rel"
    mkdir -p "$(dirname "$dest")"
    cp -f "$skill" "$dest"
  done < <(find "$dir" -name SKILL.md -type f)

  while IFS= read -r file; do
    rel="${file#"$PACKAGE_ROOT"/}"
    dest="$SKILLS_DST/$rel"
    mkdir -p "$(dirname "$dest")"
    cp -f "$file" "$dest"
  done < <(find "$dir" -type f ! -name SKILL.md)

  echo "Installed: $name"
done

legacy_remove=(
  "writing-plans/writing-plans"
  "grill-me/grill-me"
  "webapp-testing/webapp-testing"
  "debug/debug"
  "github/github"
  "git-in-clone"
  "test-driven-development/test-driven-development"
  "brainstorming/brainstorming"
)

echo ""
echo "=== Removing known legacy duplicate folders ==="
for rel in "${legacy_remove[@]}"; do
  path="$SKILLS_DST/$rel"
  if [[ -e "$path" ]]; then
    rm -rf "$path"
    echo "Deleted legacy: $rel"
  fi
done

src_git="$SKILLS_DST/github/github/git-in-clone"
dst_git="$SKILLS_DST/github/git-in-clone"
if [[ -d "$src_git" && ! -e "$dst_git" ]]; then
  mv "$src_git" "$dst_git"
  echo "Moved: github/github/git-in-clone -> github/git-in-clone"
fi

echo ""
echo "=== Resolving duplicate skill names (keep skills-pack path) ==="
declare -A SEEN
while IFS= read -r skill; do
  rel="${skill#"$SKILLS_DST"/}"
  sname="$(get_skill_name "$skill")"
  [[ -z "$sname" ]] && continue
  if [[ -n "${SEEN[$sname]+x}" ]]; then
    keep="${CANONICAL[$sname]:-}"
    if [[ -n "$keep" && "$rel" != "$keep" ]]; then
      rm -f "$skill"
      echo "Removed duplicate [$sname]: $rel"
    elif [[ -z "$keep" && "$rel" != "${SEEN[$sname]}" ]]; then
      rm -f "$skill"
      echo "Removed duplicate [$sname]: $rel"
    fi
  else
    SEEN["$sname"]="$rel"
  fi
done < <(find "$SKILLS_DST" -name SKILL.md -type f | sort)

mkdir -p "$HOOKS_DST"
cp "$HOOKS_SRC/session-start" "$HOOKS_DST/session-start"
chmod +x "$HOOKS_DST/session-start"
echo ""
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
