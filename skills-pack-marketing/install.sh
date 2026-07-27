# Opt-in install: marketing skills + playbook-lp-creative → ~/.cursor/skills only.
# Does NOT install to ~/.agents or ~/.claude.
# Run from: skills-maker/skills-pack-marketing/install.sh

set -euo pipefail
PACKAGE_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DST="${HOME}/.cursor/skills"

mkdir -p "$SKILLS_DST"
echo "=== skills-pack-marketing install (Cursor only) ==="
echo "Target: $SKILLS_DST"
echo "Policy: do NOT install to ~/.agents or ~/.claude"
echo ""

copied=0
for dir in "$PACKAGE_ROOT"/*/; do
  name="$(basename "$dir")"
  case "$name" in
    .* ) continue ;;
  esac
  while IFS= read -r -d '' file; do
    rel="${file#$PACKAGE_ROOT/}"
    dest="$SKILLS_DST/$rel"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]] && cmp -s "$file" "$dest"; then
      continue
    fi
    cp "$file" "$dest"
    copied=$((copied + 1))
  done < <(find "$dir" -type f -print0)
  echo "Installed: $name"
done

echo ""
echo "Files copied/updated: $copied"
echo "Done. Restart Cursor. Use /playbook-lp-creative as the entry point."
echo "See INSTALL.md for policy."
