# New Project Skill — Reference

## Bundled files (`scripts/`)

| File | Role |
|---|---|
| `scaffold.js` | Hearing UI + generate flow |
| `lib/parser.js` | Markdown template extract |
| `lib/writer.js` | Placeholder replace + collision-safe write |
| `lib/paths.js` | Destination containment, case collision, junction escape |
| `lib/plan.js` | Output path list from options |
| `lib/vars.js` | Placeholder values from hearing |
| `lib/staging.js` | Stage, validate, commit, journal rollback |
| `FILE_TEMPLATE_SOURCE.md` | Code and doc templates |
| `MASTER_PROTOCOL_SOURCE.md` | Hidem protocol template |
| `package.json` | `@clack/prompts`, `picocolors` |

## Canonical source

The canonical copy is `skills-maker/skills-pack/new-project/`. Edit here, then install with `install.ps1` / `install-claude.ps1` after approval.

`original-source-maker` is historical comparison material only. Do not copy from it as the source of truth.

## Hidem profile

Generated only when the user turns it on:

- `PROJECT.md` — purpose, scope, non-goals
- `.project_rules/MASTER_PROTOCOL.md` — working rules

README and `AGENTS.md` remain the general entry. Hidem files are an extra layer, not "the single source of truth".

## Hearing (CLI)

1. Name, description, author
2. Distribution: Web / Tauri / MAUI / docs-only
3. Connectivity: Offline / Online / Hybrid
4. Modules (not MAUI, not docs-only)
5. Git pattern A (`main`) / B (`main` + `develop`)
6. AI-maintained → `AGENTS.md`
7. Hidem profile on/off
8. Destination directory

## After generate

Print setup commands. Do not execute `npm install`, git init, commit, push, or a dev server.

## Troubleshoot

| Problem | Fix |
|---|---|
| `Cannot find module '@clack/prompts'` | `npm install` in this skill's `scripts/` |
| Template missing | `FILE_TEMPLATE_SOURCE.md` next to `scaffold.js` |
| Collision | Stop. Do not overwrite. Pick an empty dest or remove the conflicting file yourself |
