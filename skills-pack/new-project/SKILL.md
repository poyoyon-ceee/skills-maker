---
name: new-project
description: >-
  Use when project-foundation classified the target as new, or when the user
  clearly wants a greenfield scaffold in an empty directory. Use when the user
  says 新規プロジェクト, プロジェクト立ち上げ, scaffold, or アプリを作りたい and the
  folder has no existing project files. Do not use for existing repositories,
  feature work, or bug fixes.
disable-model-invocation: true
---

# New Project

Day 0 scaffold for a **new** directory. Existing repos go through `doc-maint`.

## Script location

Resolve `scripts/scaffold.js` from **this skill's directory** (the folder that contains this `SKILL.md`). Do not hardcode `~/.claude`, `~/.cursor`, or `~/.codex`.

If `scripts/node_modules` is missing, run `npm install` inside `scripts/` first (scaffolder dependencies only).

## Workflow

1. Confirm the destination is the intended new project directory.
2. Run the CLI. The user answers in the terminal. Do not Write project files by hand.
3. The CLI previews every output path, Hidem on/off, and collisions. It writes nothing until confirmed.
4. One collision → stop with zero writes. Paths outside the destination, including junction/symlink escape, are rejected.
5. After success, report generated files, profile, next docs to read, and setup commands. Do not run `npm install`, git init, commit, push, or a dev server.

## Hearing (CLI)

Project name, purpose, Web / Tauri / MAUI / docs-only, connectivity, modules, git pattern, AI-maintained (`AGENTS.md`), Hidem profile, destination.

Generate from need. Do not use Minimal / Standard / Full to dump extra Markdown.

Always: `README.md`.  
If other canonical docs exist: `docs/index.md`.  
Hidem on: `PROJECT.md` and `.project_rules/MASTER_PROTOCOL.md` as an extra layer.  
Hidem off: do not create those files.

## Forbidden

- Overwriting existing files
- Running the scaffolder on an existing project
- Claiming npm install finished when it was not run
- Empty AI review / improvement prompt files
- Treating Hidem files as the general standard

Details: [reference.md](reference.md).
