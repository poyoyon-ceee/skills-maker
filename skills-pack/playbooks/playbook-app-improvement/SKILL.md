---
name: playbook-app-improvement
description: >-
  Existing app improvement playbook. Runs systematic-debugging, improve-codebase-architecture,
  requesting-code-review, and react-best-practices. Use when fixing recurring bugs,
  reducing complexity, or hardening AI-generated web apps.
disable-model-invocation: true
---

# App Improvement Playbook

根本原因デバッグ → アーキ改善 → コードレビュー → React ベストプラクティス。

## When to use

- 過去に作った Web アプリや自動化スクリプトの改善
- 直しても再発するバグ、複雑化したコードベース

## Prerequisites

| Skill | Status |
|-------|--------|
| systematic-debugging | Required — usually already global |
| improve-codebase-architecture | Required |
| requesting-code-review | Required — use instead of generic code-review |
| react-best-practices | Required for React/Next apps; skip for non-React |

## Workflow

### Step 1 — Debug

1. Read and follow `systematic-debugging` SKILL.md.
2. Find root cause before proposing fixes.

### Step 2 — Architecture

1. Read and follow `improve-codebase-architecture` SKILL.md.
2. List structural issues and prioritized refactors.

### Step 3 — Code review

1. Read and follow `requesting-code-review` SKILL.md.
2. Review changes before merge or release.

### Step 4 — React polish (if applicable)

1. If the stack is React/Next, read and follow `react-best-practices` SKILL.md.
2. Skip this step for non-React projects.

## Done when

- Root cause documented for active bugs
- Architecture improvement plan exists
- Review findings addressed or explicitly deferred
- React-specific issues fixed if applicable

## Do not

- Patch symptoms without Step 1
- Install duplicate `code-review` skill — use requesting-code-review
