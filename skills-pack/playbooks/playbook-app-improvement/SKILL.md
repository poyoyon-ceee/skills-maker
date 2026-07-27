---
name: playbook-app-improvement
description: >-
  Existing app improvement playbook. Runs systematic-debugging, improve-codebase-architecture,
  requesting-code-review, and react-best-practices. Use when fixing recurring bugs,
  reducing complexity, or hardening AI-generated web apps. Starts with an adaptive
  proposal gate — wait for GO before debugging or refactoring.
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

## Adaptive proposal gate (do this first)

**HARD GATE:** Do not read step skills or start Workflow until the user approves an adaptive plan.
Exception: if the user already said `GO` / `通しで` with a clear step map (e.g. from `/route-playbook`), present the adapted Done-when briefly and proceed.

1. Restate the symptom / improvement goal and stack (React or not).
2. Map each Workflow step to **必須** / **任意** / **スキップ** with one-line reason.
3. Recommend **チェックポイント** or **通し**.
4. Flag gaps (non-React → skip Step 4).
5. Present and wait:

```markdown
### Adaptive plan
- Playbook: playbook-app-improvement
- Goal: <one line>
- Steps:
  - Step 1 Debug — …
  - Step 2 Architecture — …
  - Step 3 Code review — …
  - Step 4 React polish — …
- Mode: チェックポイント | 通し
- Prerequisites: OK | <gaps>
- Done-when (adapted): <only non-skipped steps>
```

Reply: `GO` / `通しで` / `プラン修正: …`

After approval, redefine "Done when" to the adapted list.

## Workflow

### Step 1 — Debug

1. Read and follow `systematic-debugging` SKILL.md.
2. Find root cause before proposing fixes.

### Step 2 — Architecture

1. Read and follow `improve-codebase-architecture` SKILL.md.
2. List structural issues and prioritized refactors.

### Step 3 — Code review

1. Read and follow `requesting-code-review` SKILL.md.
2. Review changes or the target area with a fresh context.

### Step 4 — React polish (if applicable)

1. Only for React / Next apps: read and follow `react-best-practices` SKILL.md.
2. Apply high-impact performance and structure fixes.

## Done when

- Root cause documented (if Step 1 ran)
- Priority improvements listed or applied
- Review notes exist for changed areas
- (After adaptive gate: only approved non-skipped steps apply)

## Do not

- Patch symptoms without Step 1 when bugs are the reason for the playbook
- Force React polish on non-React codebases
- Skip the adaptive proposal gate unless user already approved a plan
