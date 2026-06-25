---
name: git-in-clone
description: 指定した GitHub リポジトリを現在の空ディレクトリに `git clone .` で取得する。/git-in-clone または「このフォルダにクローン」で使う。
disable-model-invocation: true
---

# Git In Clone

Clone a **user-specified** GitHub repository into the **current directory** (`.`).

## Prerequisites

Before starting, verify:

1. `git` is installed: `git --version`
2. Current directory is the target project root (workspace root or folder the user opened)
3. Current directory is **empty enough** for `git clone .` (no existing `.git`, no conflicting files)

If `git` is missing, stop and tell the user to install Git.

## Workflow

Copy this checklist and track progress:

```
Task Progress:
- [ ] Step 1: Ask for repository
- [ ] Step 2: Validate repository and directory
- [ ] Step 3: Run git clone
- [ ] Step 4: Report result to user
```

### Step 1: Ask for repository

Ask the user which repository to clone. Use `AskQuestion` when available; otherwise ask in chat.

Accept either:

- Full HTTPS URL: `https://github.com/owner/repo.git`
- Shorthand: `owner/repo`

Do not invent a repository. Wait for explicit user input.

### Step 2: Validate repository and directory

**Repository:**

- If input is `owner/repo`, use `https://github.com/owner/repo.git`
- If input is a URL, use it as-is (normalize trailing `.git` if missing for GitHub HTTPS)
- Optional check: `gh repo view owner/repo` — if not found, stop and ask for correction

**Directory checks from the project root:**

- If `.git` exists → stop. Directory is already a git repo; ask whether to abort or use a different folder.
- List directory contents. If non-hidden files or folders exist (other than `.` / `..`), stop and warn. `git clone .` fails on non-empty directories.
- Hidden-only contents (e.g. `.vscode`) may still block clone — if clone fails, report the error and ask the user to clear the folder.

Do not delete user files without explicit approval.

### Step 3: Run git clone

From the project root:

```bash
git clone <REPO_URL> .
```

- Target is always `.` (current directory)
- Use the URL resolved in Step 2

### Step 4: Report result

Report clearly:

- Clone succeeded or failed
- Repository URL used
- Current branch name (`git branch --show-current`)
- Remote `origin` URL (`git remote get-url origin`)
- Brief note on next steps (e.g. open project, run setup if README specifies)

## Error handling

| Situation | Action |
|-----------|--------|
| Directory not empty | Stop; list blocking items; ask user to empty folder or pick another path |
| `.git` already exists | Stop; ask abort or different folder |
| Repo not found | Ask for a different owner/repo or URL |
| Network / auth failure | Report error; suggest checking network or GitHub access |
| Clone partially failed | Report error; do not run destructive cleanup unless user asks |

## Constraints

- NEVER update git config (user/global)
- NEVER delete files in the target directory without explicit user approval
- NEVER commit or push unless the user explicitly asks
- Run clone only in the directory the user is working in (workspace root)
