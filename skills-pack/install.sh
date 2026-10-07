#!/usr/bin/env bash
# Install global skills from skills-pack.
#
# Layout (single source of truth per skill, no duplicates):
#   ~/.agents/skills/<skill-name>/    skills whose installTargets contain agents
#   ~/.cursor/skills/<skill-name>/    skills whose installTargets contain cursor
#   ~/.cursor/hooks/                  session hook (Cursor-specific format)
#
# Routing comes from MANIFEST.json installTargets. AGENTS_DEST and CURSOR_DEST
# override the destination directories; when empty, $HOME/.agents/skills and
# $HOME/.cursor/skills are used.
#
# Category folders (playbooks/, superpowers/, github/, debug/) exist for
# organisation inside this pack only; they are stripped on install because
# Codex is not confirmed to recurse into nested skill directories.
set -euo pipefail

PACKAGE_ROOT="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DST="${AGENTS_DEST:-$HOME/.agents/skills}"
CURSOR_DST="${CURSOR_DEST:-$HOME/.cursor/skills}"
CURSOR_BAK="$(dirname "$CURSOR_DST")/skills.bak"
HOOKS_DST="$HOME/.cursor/hooks"
HOOKS_CONFIG="$HOME/.cursor/hooks.json"
HOOKS_SRC="$PACKAGE_ROOT/_hooks"

SKIP_TOP=("_hooks" "_claude")

if command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
else
  echo "ERROR: python is required to read MANIFEST.json" >&2
  exit 1
fi

target_file="$(mktemp)"
if ! "$PYTHON_BIN" - "$PACKAGE_ROOT/MANIFEST.json" >"$target_file" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8-sig") as handle:
    rows = json.load(handle)
if not isinstance(rows, list):
    print("ERROR: MANIFEST.json must be a list", file=sys.stderr)
    sys.exit(1)
for row in rows:
    name = row.get("name")
    targets = row.get("installTargets")
    if not isinstance(name, str) or not name:
        print("ERROR: MANIFEST row missing name", file=sys.stderr)
        sys.exit(1)
    if (
        not isinstance(targets, list)
        or not targets
        or any(not isinstance(item, str) or not item for item in targets)
    ):
        print("ERROR: installTargets missing for " + name, file=sys.stderr)
        sys.exit(1)
    if "agents" in targets and "cursor" in targets:
        print(
            "ERROR: installTargets cannot contain both agents and cursor: " + name,
            file=sys.stderr,
        )
        sys.exit(1)
    print(name + "\t" + ",".join(targets))
PY
then
  rm -f "$target_file"
  exit 1
fi

declare -A TARGETS
while IFS=$'\t' read -r name targets; do
  # Windows python writes CRLF; drop the CR so "agents" does not become "agents\r".
  name="${name%$'\r'}"
  targets="${targets%$'\r'}"
  [[ -z "$name" ]] && continue
  TARGETS["$name"]="$targets"
done <"$target_file"
rm -f "$target_file"

has_target() {
  local list="$1" needle="$2" item
  local IFS=','
  for item in $list; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

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

    if [[ -z "${TARGETS[$name]+x}" ]]; then
      echo "ERROR: no MANIFEST installTargets for skill '$name'"
      exit 1
    fi

    if has_target "${TARGETS[$name]}" agents && has_target "${TARGETS[$name]}" cursor; then
      echo "ERROR: installTargets cannot contain both agents and cursor: $name"
      exit 1
    fi

    if has_target "${TARGETS[$name]}" agents; then
      dest="$AGENTS_DST/$name"
      tag="agents"
      agents_count=$((agents_count + 1))
    elif has_target "${TARGETS[$name]}" cursor; then
      dest="$CURSOR_DST/$name"
      tag="cursor"
      cursor_count=$((cursor_count + 1))
    else
      continue
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

# A cursor-targeted skill must not also live in the agents dest, and an
# agents-targeted skill must not linger in the cursor dest.
for name in "${!TARGETS[@]}"; do
  if has_target "${TARGETS[$name]}" cursor && ! has_target "${TARGETS[$name]}" agents; then
    if [[ -d "$AGENTS_DST/$name" ]]; then
      rm -rf "${AGENTS_DST:?}/$name"
      stale=$((stale + 1))
      echo "Removed from agents (cursor target): $name"
    fi
  fi
done

for path in "$CURSOR_DST"/*/; do
  [[ -d "$path" ]] || continue
  leaf="$(basename "$path")"
  if [[ -n "${TARGETS[$leaf]+x}" ]] && has_target "${TARGETS[$leaf]}" cursor; then
    continue
  fi
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
