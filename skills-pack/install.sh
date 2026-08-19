#!/usr/bin/env bash
# Install global skills from skills-pack.
#
# Layout (single source of truth per skill, no duplicates):
#   ~/.agents/skills/<skill-name>/    all portable skills, flattened
#                                     (read by Cursor, Codex, ChatGPT tooling)
#   ~/.cursor/skills/<skill-name>/    Cursor-only skills that hardcode Cursor
#                                     paths/UI (CURSOR_ONLY below)
#   ~/.cursor/hooks/                  session hook (Cursor-specific format)
#
# Category folders (playbooks/, superpowers/, github/, debug/) exist for
# organisation inside this pack only; they are stripped on install because
# Codex is not confirmed to recurse into nested skill directories.
set -euo pipefail

PACKAGE_ROOT="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DST="$HOME/.agents/skills"
CURSOR_DST="$HOME/.cursor/skills"
CURSOR_BAK="$HOME/.cursor/skills.bak"
HOOKS_DST="$HOME/.cursor/hooks"
HOOKS_CONFIG="$HOME/.cursor/hooks.json"
HOOKS_SRC="$PACKAGE_ROOT/_hooks"

SKIP_TOP=("_hooks" "_claude")
# These hardcode ~/.cursor paths or Cursor UI flows, so they stay out of the
# shared ~/.agents tree.
CURSOR_ONLY=("chat-handoff" "skill-creator" "promote-skill")

mkdir -p "$AGENTS_DST" "$CURSOR_DST"

get_skill_name() {
  awk '
    /^name:/ {
      sub(/^name:[[:space:]]*/, "")
      gsub(/^[ \t]+|[ \t]+$/, "")
      if ($0 ~ /^".*"$/ || $0 ~ /^'\''.*'\''$/) {
        sub(/^["'\'']/, "")
        sub(/["'\'']$/, "")
      }
      print
      exit
    }
  ' "$1"
}

contains() {
  local needle="$1"; shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

echo "=== skills-pack install ==="

declare -A SEEN_NAMES
agents_count=0
cursor_count=0

for dir in "$PACKAGE_ROOT"/*/; do
  top="$(basename "$dir")"
  contains "$top" "${SKIP_TOP[@]}" && continue

  while IFS= read -r skill; do
    src_dir="$(dirname "$skill")"
    name="$(get_skill_name "$skill")"
    [[ -z "$name" ]] && name="$(basename "$src_dir")"

    if [[ -n "${SEEN_NAMES[$name]+x}" ]]; then
      echo "ERROR: duplicate skill name '$name' in pack:"
      echo "  ${SEEN_NAMES[$name]}"
      echo "  $src_dir"
      exit 1
    fi
    SEEN_NAMES["$name"]="$src_dir"

    if contains "$name" "${CURSOR_ONLY[@]}"; then
      dest="$CURSOR_DST/$name"
      tag="cursor"
      cursor_count=$((cursor_count + 1))
    else
      dest="$AGENTS_DST/$name"
      tag="agents"
      agents_count=$((agents_count + 1))
    fi

    mkdir -p "$dest"
    (cd "$src_dir" && find . -type f -print0) | while IFS= read -r -d '' rel; do
      mkdir -p "$dest/$(dirname "$rel")"
      cp -f "$src_dir/$rel" "$dest/$rel"
    done

    echo "Installed [$tag]: $name"
  done < <(find "$dir" -name SKILL.md -type f | sort)
done

echo ""
echo "=== Cleaning stale copies ==="
stale=0

# A Cursor-only skill must not also live in ~/.agents, and a portable skill must
# not linger in ~/.cursor - either case makes the same name resolve twice.
for name in "${CURSOR_ONLY[@]}"; do
  if [[ -d "$AGENTS_DST/$name" ]]; then
    rm -rf "${AGENTS_DST:?}/$name"
    stale=$((stale + 1))
    echo "Removed from agents (Cursor-only): $name"
  fi
done

for path in "$CURSOR_DST"/*/; do
  [[ -d "$path" ]] || continue
  leaf="$(basename "$path")"
  contains "$leaf" "${CURSOR_ONLY[@]}" && continue
  [[ -n "$(find "$path" -name SKILL.md -type f -print -quit)" ]] || continue

  mkdir -p "$CURSOR_BAK"
  rm -rf "${CURSOR_BAK:?}/$leaf"
  mv "$path" "$CURSOR_BAK/$leaf"
  stale=$((stale + 1))
  echo "Moved to skills.bak (now owned by ~/.agents): $leaf"
done

[[ $stale -eq 0 ]] && echo "(nothing stale)"

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
echo "=== Summary ==="
echo "~/.agents/skills: $(find "$AGENTS_DST" -name SKILL.md -type f | wc -l | tr -d ' ')"
echo "~/.cursor/skills: $(find "$CURSOR_DST" -name SKILL.md -type f | wc -l | tr -d ' ')"

dupes="$(find "$AGENTS_DST" "$CURSOR_DST" -name SKILL.md -type f -exec awk '/^name:/ { sub(/^name:[[:space:]]*/, ""); print; exit }' {} \; | sort | uniq -d)"
if [[ -n "$dupes" ]]; then
  echo "WARNING: duplicate names remain:"
  echo "$dupes" | sed 's/^/  /'
else
  echo "OK: no duplicate skill names."
fi

echo ""
echo "Done. Restart Cursor, then check Customize -> Skills and Hooks."
echo "See INSTALL.md in this folder for details."
