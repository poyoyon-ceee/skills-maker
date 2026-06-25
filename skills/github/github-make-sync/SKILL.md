---
name: github-make-sync
description: 指定した名前で非公開 GitHub リポジトリを作成し、gh CLI で現在のプロジェクトに origin を設定する。/github-make-sync、GitHub リポ作成・同期・origin 設定時に使う。
disable-model-invocation: true
---

# GitHub Make Sync

Create a **private** GitHub repository and link it to the **current project directory**.

## Prerequisites

Before starting, verify:

1. `gh` is installed: `gh --version`
2. `gh` is authenticated: `gh auth status`
3. Current directory is the target project root

If `gh` is missing or not logged in, stop and tell the user how to fix it (`gh auth login`).

## Workflow

Copy this checklist and track progress:

```
Task Progress:
- [ ] Step 1: Ask for repository name
- [ ] Step 2: Validate name and check conflicts
- [ ] Step 3: Ensure git is initialized
- [ ] Step 4: Create private repo and link origin
- [ ] Step 5: Push if commits exist
- [ ] Step 6: Report result to user
```

### Step 1: Ask for repository name

Ask the user for the GitHub repository name. Use `AskQuestion` when available; otherwise ask in chat.

Do not invent a name. Wait for explicit user input.

### Step 2: Validate name and check conflicts

**GitHub repo name rules:**
- Lowercase letters, numbers, hyphens only
- No leading/trailing hyphen
- Reasonable length (typically under 100 chars)

**Checks to run:**
- `gh repo view <owner>/<name>` — if exists, stop and ask for another name
- `git remote get-url origin` — if `origin` already exists, ask whether to replace it or abort

### Step 3: Ensure git is initialized

If `.git` does not exist:

```bash
git init
git branch -M main
```

If commits exist, detect the current branch name and use it for push (often `main`).

### Step 4: Create private repo and link origin

From the project root:

```bash
gh repo create <REPO_NAME> --private --source=. --remote=origin
```

- Always use `--private`
- Do not pass `--public`
- Set `origin` to the new repository

If `origin` already exists and the user approved replacement:

```bash
git remote remove origin
gh repo create <REPO_NAME> --private --source=. --remote=origin
```

### Step 5: Push if commits exist

If the repo has at least one commit:

```bash
git push -u origin <current-branch>
```

If there are **no commits yet**, skip push and tell the user:

```bash
git add .
git commit -m "Initial commit"
git push -u origin main
```

### Step 6: Report result

Report clearly:

- Repository URL (`https://github.com/<owner>/<REPO_NAME>`)
- Visibility: private
- Remote: `origin` URL
- Whether push succeeded or deferred (no commits)

## Error handling

| Situation | Action |
|-----------|--------|
| Repo name already taken | Ask for a different name |
| `origin` exists | Ask replace or abort |
| `gh auth` failed | Stop; user must run `gh auth login` |
| Push rejected | Report error; do not force-push unless user explicitly requests |

## Constraints

- NEVER update git config (user/global)
- NEVER force-push to main/master unless explicitly requested
- NEVER commit unless the user explicitly asks
- Use HTTPS remote as returned by `gh` (matches user's `gh` auth setup)
