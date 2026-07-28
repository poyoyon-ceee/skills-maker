#!/usr/bin/env bash
# Promote ONE installed skill into a verified skills-maker pack.
# Looks in ~/.agents/skills first, then ~/.cursor/skills (Cursor-only skills).
# NEVER creates skills-maker root. NEVER writes if validation fails.
#
# Usage:
#   ./promote-to-pack.sh my-skill /path/to/skills-maker
#   ./promote-to-pack.sh my-skill /path/to/skills-maker skills-pack-marketing
#   ./promote-to-pack.sh my-skill /path/to/skills-maker skills-pack --force

set -euo pipefail

SkillFolderName="${1:-}"
SkillsMakerRoot="${2:-}"
PackName="${3:-skills-pack}"
Force=0
if [[ "${4:-}" == "--force" ]] || [[ "${3:-}" == "--force" ]]; then
  Force=1
  if [[ "${3:-}" == "--force" ]]; then
    PackName="skills-pack"
  fi
fi

if [[ -z "$SkillFolderName" || -z "$SkillsMakerRoot" ]]; then
  echo "Usage: $0 <skill-folder-name> <skills-maker-root> [skills-pack|skills-pack-marketing] [--force]" >&2
  exit 1
fi

if [[ "$SkillFolderName" == *"/"* || "$SkillFolderName" == *"\\"* || "$SkillFolderName" == "." || "$SkillFolderName" == ".." ]]; then
  echo "Skill folder name must be a single name, not a path: $SkillFolderName" >&2
  exit 1
fi

if [[ "$PackName" != "skills-pack" && "$PackName" != "skills-pack-marketing" ]]; then
  echo "PackName must be skills-pack or skills-pack-marketing: $PackName" >&2
  exit 1
fi

validate_root() {
  local root="$1"
  local pack_name="$2"
  if [[ ! -d "$root" ]]; then
    echo "Root directory does not exist: $root" >&2
    return 1
  fi
  local pack="$root/$pack_name"
  if [[ ! -d "$pack" ]]; then
    echo "Pack directory missing (will not create): $pack" >&2
    return 1
  fi
  if [[ ! -f "$pack/install.ps1" && ! -f "$pack/install.sh" && ! -f "$pack/MANIFEST.json" && ! -f "$pack/引き継ぎ.md" && ! -f "$pack/INSTALL.md" ]]; then
    echo "Pack has no install/MANIFEST/引き継ぎ markers — refusing: $pack" >&2
    return 1
  fi
  return 0
}

SRC=""
for root in "${HOME}/.agents/skills" "${HOME}/.cursor/skills"; do
  if [[ -d "${root}/${SkillFolderName}" ]]; then
    SRC="${root}/${SkillFolderName}"
    break
  fi
done

if [[ -z "$SRC" ]]; then
  echo "Global skill not found in ~/.agents/skills or ~/.cursor/skills (run Gate 1 first): $SkillFolderName" >&2
  exit 1
fi
if [[ ! -f "${SRC}/SKILL.md" ]]; then
  echo "SKILL.md missing in source: ${SRC}/SKILL.md" >&2
  exit 1
fi

if ! validate_root "$SkillsMakerRoot" "$PackName"; then
  echo "Refusing to write." >&2
  exit 1
fi

PACK_ROOT="${SkillsMakerRoot}/${PackName}"
DST="${PACK_ROOT}/${SkillFolderName}"

if [[ -e "$DST" && "$Force" -ne 1 ]]; then
  echo "Destination already exists (pass --force to overwrite): $DST" >&2
  exit 1
fi

echo "Source:      $SRC"
echo "Destination: $DST"
echo "Pack:        $PackName"

rm -rf "$DST"
mkdir -p "$(dirname "$DST")"
cp -R "$SRC" "$DST"

# Regenerate MANIFEST.json
MANIFEST="${PACK_ROOT}/MANIFEST.json"
TMP="$(mktemp)"
python3 - <<'PY' "$PACK_ROOT" "$TMP"
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
out = Path(sys.argv[2])
CURSOR_ONLY = {"chat-handoff", "skill-creator", "promote-skill"}
entries = []
for skill_md in root.rglob("SKILL.md"):
    rel = skill_md.relative_to(root).as_posix()
    if rel.startswith("_hooks/") or rel.startswith("_claude/"):
        continue
    name = None
    for line in skill_md.read_text(encoding="utf-8").splitlines()[:15]:
        if line.startswith("name:"):
            name = line.split(":", 1)[1].strip()
            break
    if name:
        target = "~/.cursor/skills" if name in CURSOR_ONLY else "~/.agents/skills"
        entries.append({"name": name, "path": rel, "installTarget": f"{target}/{name}/"})
entries.sort(key=lambda e: e["name"])
out.write_text(json.dumps(entries, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")
print(len(entries))
PY
mv "$TMP" "$MANIFEST"

COUNT=$(python3 -c "import json; print(len(json.load(open('$MANIFEST', encoding='utf-8'))))")
echo ""
echo "OK. Copied skill and refreshed MANIFEST ($COUNT entries)."
echo "Manifest: $MANIFEST"
echo "Commit separately if desired — this script does not commit."
