---
name: obsidian-vault
description: Search, create, and organize notes in the Obsidian vault at D:\vault with wikilinks and index notes. Use when the user wants to find, create, move, or structure vault content. For Obsidian markdown syntax (callouts, frontmatter, embeds) use obsidian-markdown; for .canvas files use json-canvas.
---

# Obsidian Vault

## Vault location

`D:\vault`

Windows absolute path. Prefer Grep/Glob/Read tools with this path.

Optional subfolders:

- `D:\vault\canvas\` — `.canvas` files (see json-canvas skill)
- `D:\vault\_inbox\` — unprocessed notes (lower priority for AI search)

Evergreen notes: mostly flat at vault root, or use links and index notes.

## Related skills

| Skill | Use when |
|-------|----------|
| obsidian-markdown | callouts, properties, embeds, Obsidian Flavored Markdown syntax |
| json-canvas | creating or editing `.canvas` files |

## Naming conventions

- **Index notes**: aggregate related topics (e.g., `Skills Index.md`, `RAG Index.md`)
- **Title case** for all note names
- Prefer links and index notes over deep folder nesting

## Linking

- Use Obsidian `[[wikilinks]]` syntax: `[[Note Title]]`
- Notes link to dependencies/related notes at the bottom
- Index notes are lists of `[[wikilinks]]`

## Workflows

### Search for notes

Use Grep/Glob tools on `D:\vault`:

```powershell
# Search by filename
Get-ChildItem -Path "D:\vault" -Recurse -Filter "*.md" | Where-Object { $_.Name -match "keyword" }

# Search by content
Get-ChildItem -Path "D:\vault" -Recurse -Filter "*.md" | Select-String -Pattern "keyword" -List
```

### Create a new note

1. Use **Title Case** for filename under `D:\vault\`
2. Write content as a unit of learning (per vault rules)
3. Add `[[wikilinks]]` to related notes at the bottom
4. Update the relevant Index note
5. If part of a numbered sequence, use the hierarchical numbering scheme

### Find related notes

Search for `[[Note Title]]` across the vault to find backlinks (Grep on `D:\vault`).

### Find index notes

```powershell
Get-ChildItem -Path "D:\vault" -Recurse -Filter "*Index*.md"
```
