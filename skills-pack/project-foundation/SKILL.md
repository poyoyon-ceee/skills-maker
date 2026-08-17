---
name: project-foundation
description: >-
  Use when starting a new app or project, scaffolding a repository, auditing or
  restructuring existing README, docs, PROJECT.md, or AGENTS.md, or standardizing
  project documentation. Use when the user says 新規プロジェクト, プロジェクト立ち上げ,
  アプリを作りたい, scaffold, READMEを直して, docsを整理して, 文書をきれいにして,
  or documentation is stale, duplicated, or missing an entry point. Do not use
  for feature work, bug fixes, or non-documentation refactors.
---

# Project Foundation

共通入口。新規か既存かを判定し、書き込みはしない。

## Classify

Run the bundled classifier from this skill's `scripts/` directory (the folder that contains this `SKILL.md`, not a vendor home path):

```text
node <this-skill>/scripts/classify-project.js <target-dir>
```

It prints exactly one of: `new`, `existing`, `ambiguous`.

Rules if the script cannot run:

- `new`: no source, manifest, README, or docs. Git init with no commits and no project files still counts as new.
- `existing`: commits, README, source, docs, or a manifest (`package.json`, `Cargo.toml`, `pyproject.toml`, `*.csproj`, `go.mod`).
- `ambiguous`: only hidden or unrelated-looking files, or the new/existing call is unsafe.

## Route

- `new` → follow `new-project`
- `existing` → follow `doc-maint` in audit mode (read-only until the user approves)
- `ambiguous` → stop. Show what was found. Ask the user.

Do not create, edit, move, or delete files during classification.

## Documentation standard

Read [references/documentation-standard.md](references/documentation-standard.md) before describing what "standard" means. Hidem files (`PROJECT.md`, `.project_rules/MASTER_PROTOCOL.md`) are an optional profile, not the default core.
