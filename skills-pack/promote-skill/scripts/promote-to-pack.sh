#!/usr/bin/env bash
# Promote ONE installed skill into a verified skills-maker pack.
# Looks in ~/.agents/skills, then ~/.cursor/skills, then ~/.claude/skills.
# NEVER creates skills-maker root. NEVER writes if validation fails.
#
# 登録経路ではない。新規・更新は incoming 4箱と scripts/sync-incoming.ps1。
# このスクリプトは global から pack への直コピーなので、通常はここで止める。
# どうしても直コピーするときだけ --allow-direct-copy。
#
# Usage:
#   ./promote-to-pack.sh my-skill /path/to/skills-maker --allow-direct-copy
#   ./promote-to-pack.sh my-skill /path/to/skills-maker skills-pack-marketing --allow-direct-copy
#   ./promote-to-pack.sh my-skill /path/to/skills-maker skills-pack --force --allow-direct-copy

set -euo pipefail

AllowDirect=0
Filtered=()
for arg in "$@"; do
  if [[ "$arg" == "--allow-direct-copy" ]]; then
    AllowDirect=1
  else
    Filtered+=("$arg")
  fi
done
if ((${#Filtered[@]} > 0)); then
  set -- "${Filtered[@]}"
else
  set --
fi

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

if [[ "$AllowDirect" -ne 1 ]]; then
  echo "ERROR: promote-to-pack は登録経路ではない。incoming の4箱に置いて scripts/sync-incoming.ps1 を使え。直コピーが必要なときだけ --allow-direct-copy を付ける。" >&2
  exit 1
fi

if [[ -z "$SkillFolderName" || -z "$SkillsMakerRoot" ]]; then
  echo "Usage: $0 <skill-folder-name> <skills-maker-root> [skills-pack|skills-pack-marketing] [--force] --allow-direct-copy" >&2
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
for root in "${HOME}/.agents/skills" "${HOME}/.cursor/skills" "${HOME}/.claude/skills"; do
  if [[ -d "${root}/${SkillFolderName}" ]]; then
    SRC="${root}/${SkillFolderName}"
    break
  fi
done

if [[ -z "$SRC" ]]; then
  echo "Global skill not found in ~/.agents/skills, ~/.cursor/skills, or ~/.claude/skills (run Gate 1 first): $SkillFolderName" >&2
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
PYTHONPATH="${SkillsMakerRoot}" python3 - <<'PY' "$PACK_ROOT" "$TMP" "$SkillsMakerRoot"
import json, sys
from pathlib import Path

sys.path.insert(0, sys.argv[3])
from scripts.incoming_lib import legacy_install_target, migration_targets

root = Path(sys.argv[1])
out = Path(sys.argv[2])


def strip_quotes(raw: str) -> str:
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "\"'":
        return raw[1:-1]
    return raw


def normalize_manifest_name(name: str) -> str:
    return strip_quotes(name)


existing_by_name: dict[str, list[str]] = {}
manifest_path = root / "MANIFEST.json"
if manifest_path.is_file():
    text = manifest_path.read_text(encoding="utf-8-sig")
    for entry in json.loads(text):
        targets = entry.get("installTargets")
        if targets:
            key = normalize_manifest_name(entry["name"])
            existing_by_name[key] = list(targets)

entries = []
for skill_md in root.rglob("SKILL.md"):
    rel = skill_md.relative_to(root).as_posix()
    if rel.startswith("_hooks/") or rel.startswith("_claude/"):
        continue
    name = None
    for line in skill_md.read_text(encoding="utf-8").splitlines()[:15]:
        if line.startswith("name:"):
            name = strip_quotes(line.split(":", 1)[1])
            break
    if not name:
        continue
    if name in existing_by_name:
        install_targets = existing_by_name[name]
    else:
        try:
            install_targets = migration_targets(name)
        except ValueError:
            print("incoming sync required; refusing to guess installTargets", file=sys.stderr)
            sys.exit(1)
    entries.append(
        {
            "name": name,
            "path": rel,
            "installTargets": install_targets,
            "installTarget": legacy_install_target(install_targets, name),
        }
    )
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
