---
name: doc-maint
description: Use when a repository's README or docs need auditing, 整理, consolidation, restructuring, freshness checks, duplicate removal, or clearer onboarding for humans and AI tools.
---

# Doc Maint

## Objective

Turn repository documentation into a small, evidence-based source of truth. Make the project understandable without multiplying Markdown files or changing application code.

## Non-negotiable boundaries

- Modify documentation only. Change code, configuration, tests, or build scripts only when the user explicitly requests code changes.
- Preserve existing architecture, conventions, and all pre-existing uncommitted changes. Never discard, overwrite, stash, stage, or reformat unrelated work.
- Treat source code, executable configuration, tests, and verified behavior as evidence—not permission to modify them.
- Never invent business facts. Mark claims that cannot be verified as `要確認`.
- Work on `dev`. If Git is present and `dev` does not exist, or switching would risk uncommitted work, stop before editing and ask how to proceed. Never perform this work on `main`.
- Do not commit or push unless explicitly requested. Never merge to `main` without an explicit instruction naming that merge.
- Do not delete a document until its unique useful content has been preserved, inbound references have been checked, and the deletion is recoverable through version control or user-approved backup.

## Workflow

### 1. Establish scope and safety

1. Read repository-level instructions.
2. Inspect the current branch, worktree status, ignored files when relevant, and existing diffs.
3. Identify user-owned changes and avoid overlapping them.
4. Confirm that the task is documentation-only unless the user explicitly broadened it.

### 2. Build an evidence inventory

Inspect:

- root README files and `docs/`;
- all tracked Markdown and text documentation;
- source tree and entry points;
- manifests, environment examples, schemas, CI, build/run scripts, and deployment configuration;
- tests and fixtures that reveal intended behavior;
- `.claude`, `.cursor`, `.codex`, `.agent`, `.agents`, and similar AI-specific folders;
- Git history only when it helps resolve freshness, intent, or supersession.

Record each document's purpose, overlap, conflicts, inbound links, apparent freshness, and unique information. Use [references/audit-checklist.md](references/audit-checklist.md) for large or messy repositories.

### 3. Resolve claims by evidence

Prefer, in order:

1. verified current behavior;
2. executable configuration and schemas;
3. tests and CI;
4. current source structure;
5. recent accepted history;
6. prose consistent with the above.

Do not silently choose between plausible conflicting business claims. Preserve the conflict in the appropriate canonical document and label it `要確認`.

### 4. Design the smallest canonical set

Use `README.md` as the concise project entry point and `docs/index.md` as the documentation hub. Add or retain `docs/spec.md`, `docs/architecture.md`, `docs/development.md`, and `docs/changelog.md` only when the repository has enough distinct content to justify them.

Do not create `AI_CONTEXT.md`, `docs/README.md`, summary reports, “final/latest/new” variants, or empty placeholder documents when the canonical files can hold the information. Read [references/documentation-structure.md](references/documentation-structure.md) before restructuring.

### 5. Consolidate and edit

- Make `README.md` answer: what this is, its verified status, major capabilities, prerequisites, shortest verified run/use path, important inputs/outputs, limitations, and where detailed docs live.
- Make `docs/index.md` list only existing canonical documents, their authority, and when to read them.
- Merge unique, current facts into the correct canonical document.
- Move shared project knowledge out of AI-specific folders. Leave only tool-specific settings, commands, metadata, or short pointers to canonical docs.
- Update links after moves or deletions.
- Prefer updating an existing suitable canonical file over creating another Markdown file.
- Keep historical decisions only when they explain current constraints; otherwise rely on Git history.

### 6. Verify before deletion and completion

- Compare documentation against the inspected code/config/tests.
- Search for stale commands, old names, duplicate claims, and broken relative links.
- Run existing documentation checks when safe.
- Review the final diff and confirm user changes remain intact.
- Delete superseded files only after consolidation and reference checks. If safety is uncertain, keep the file and report it.

## Required completion report

Report these sections even when empty:

1. **Created**
2. **Updated**
3. **Merged into canonical docs**
4. **Deleted** — include why each deletion was safe
5. **Kept intentionally** — include why
6. **Conflicts and stale information found**
7. **`要確認` items**
8. **Verification performed and results**
9. **Git actions** — branch, commit, push, and merge status
10. **Code changes** — normally `None`

Do not claim completion if links are unverified, deletion safety is unresolved, the work occurred on `main`, or user-owned changes may have been altered.
