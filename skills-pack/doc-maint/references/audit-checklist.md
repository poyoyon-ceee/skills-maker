# Documentation Audit Checklist

Use this reference for repositories with many, conflicting, or risky documents.

## Safety

- [ ] Read repository instructions.
- [ ] Confirm branch and worktree state.
- [ ] Identify staged, unstaged, and untracked user changes.
- [ ] Confirm work is on `dev`, not `main`.
- [ ] Confirm documentation-only scope.
- [ ] Avoid secrets, generated output, vendored dependencies, and build artifacts.

## Inventory

- [ ] Find root README files and `docs/`.
- [ ] Find tracked Markdown and documentation-like text files.
- [ ] Inspect AI-specific folders.
- [ ] Identify entry points, manifests, schemas, CI, build/run scripts, and tests.
- [ ] Check Git history only where it resolves uncertainty.
- [ ] Map inbound links to documents considered for moving or deletion.

For each document, note:

| Field | Question |
|---|---|
| Purpose | What question should this file answer? |
| Authority | Is it canonical, a pointer, history, or temporary output? |
| Evidence | Which code/config/test supports its claims? |
| Freshness | Does it describe the current repository? |
| Overlap | Where is the same information repeated? |
| Conflict | Which claims disagree? |
| Unique value | What must be preserved before consolidation? |
| References | What links to this file? |
| Action | Keep, update, merge, move, delete, or `要確認` |

## Consolidation gates

Before merging:

- [ ] Select the destination by topic, not by whichever filename looks newest.
- [ ] Preserve useful unique facts.
- [ ] Remove contradictions or label unresolved ones `要確認`.
- [ ] Avoid expanding scope into code changes.

Before deleting:

- [ ] Confirm the destination contains all useful current information.
- [ ] Check inbound links and update them.
- [ ] Confirm the file is tracked or otherwise recoverable.
- [ ] Ensure it contains no user-owned uncommitted changes.
- [ ] Keep it when any gate fails and explain why.

## Verification

- [ ] README is concise and links to existing files only.
- [ ] `docs/index.md` is a hub, not a second README.
- [ ] Commands match executable configuration or verified behavior.
- [ ] Names, paths, versions, and environment requirements are current.
- [ ] Shared project knowledge is not trapped in AI-specific folders.
- [ ] No empty placeholders or unnecessary new Markdown files exist.
- [ ] Relative links resolve.
- [ ] Final diff contains documentation changes only.
- [ ] Pre-existing uncommitted work is intact.
- [ ] Completion report includes all ten required sections.
