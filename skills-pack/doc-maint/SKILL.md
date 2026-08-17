---
name: doc-maint
description: Use when a repository's README or docs need auditing, 整理, consolidation, restructuring, freshness checks, duplicate removal, or clearer onboarding for humans and AI tools.
---

# Doc Maint

Turn repository documentation into a small, evidence-based source of truth. Do not multiply Markdown files or change application code.

既存プロジェクトは **監査（読み取り専用）→ ユーザー承認 → 適用**。承認ゲートを飛ばさない。

## Non-negotiable boundaries

- Documentation only. Change code, configuration, tests, or build scripts only when the user explicitly requests code changes.
- Preserve architecture, conventions, and all pre-existing uncommitted changes. Never discard, overwrite, stash, stage, or reformat unrelated work.
- Treat source, executable config, tests, and verified behavior as evidence—not permission to modify them.
- Never invent business facts. Unverified claims are `要確認`.
- Do not commit or push unless explicitly requested. Never merge to `main` without an explicit instruction naming that merge.
- Do not delete a document until unique useful content is preserved, inbound references are checked, and deletion is recoverable through git or a user-approved backup.
- Untracked documents are not deleted without explicit approval.

## Branch policy

Do not force a branch named `dev`.

1. Follow repository instructions (`AGENTS.md`, project rules)
2. Follow existing git practice
3. Follow an explicit user choice
4. If none of the above, propose a dedicated working branch

If default-branch edits are forbidden, move to a working branch only after the user agrees. Never stash, move, or discard uncommitted work.

## 1. Audit (read-only)

During audit do **not** create, edit, move, or delete files. Do not change branches, stash, commit, push, format, install packages, or auto-fix.

Inspect:

- Git branch, status, uncommitted changes
- Repo-level human and AI instructions
- README, docs, designs, plans
- manifests, build, tests, CI
- actual features in source
- links and inbound references
- git history only when it resolves freshness

Use [references/audit-checklist.md](references/audit-checklist.md) for large or messy repos. Read [references/documentation-structure.md](references/documentation-structure.md) before proposing a canonical set.

## 2. User-facing result

Show **only** these five labels:

| 分類 | 意味 |
|---|---|
| 維持 | 正本または必要な履歴として残す |
| 統合 | 固有情報を他の正本へ移す |
| 修正 | 古い、または実装と矛盾する内容を直す |
| 移動 | 設計・計画・ツール固有文書を適切な場所へ移す |
| 要確認 | 根拠不足。ユーザー判断が必要 |

Internal labels (duplicate, stale, orphaned, …) stay internal. Do not create files or folders per internal label.

Each item includes: operation, reason, destination, affected links, recoverability. The user may approve the whole plan or individual operations.

Present the audit in chat. Do not write an audit report file unless the user asks; then put it in existing `docs/plans/`.

If Hidem files already exist (`PROJECT.md`, `.project_rules/MASTER_PROTOCOL.md`), protect them and point to them from README/AGENTS. If they do not exist, offer them as an option. Do not add them automatically.

## 3. Re-check before apply

- Target files are unchanged since audit
- Destinations were not newly created by someone else
- No overlap with user-owned edits
- Unique content of delete candidates is already in a canonical doc
- Inbound link targets are decided
- The plan is documentation-only

On mismatch, stop the affected items and update the plan.

## 4. Apply order (approved items only)

1. Create or update canonical docs
2. Merge unique information
3. Update links
4. Move documents
5. Check links
6. Final check of delete candidates
7. Delete
8. Verify the whole set

## Required completion report

1. **Created**
2. **Updated**
3. **Merged into canonical docs**
4. **Deleted** — why each deletion was safe
5. **Kept intentionally** — why
6. **Conflicts and stale information found**
7. **`要確認` items**
8. **Verification performed and results**
9. **Git actions** — branch, commit, push, merge status
10. **Code changes** — normally `None`

Do not claim completion if links are unverified, deletion safety is unresolved, or user-owned changes may have been altered.
