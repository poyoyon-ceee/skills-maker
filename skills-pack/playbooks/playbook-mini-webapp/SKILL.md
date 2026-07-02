---
name: playbook-mini-webapp
description: >-
  Mini web app build playbook. Runs to-prd, frontend-design, web-artifacts-builder,
  webapp-testing, and verification-before-completion. Use for internal tools,
  forms, and simple dashboards.
disable-model-invocation: true
---

# Mini Web App Playbook

PRD → UI 設計 → 実装 → ブラウザ QA → 完了検証。

## When to use

- 社内管理表、入力フォーム、簡易ダッシュボードを作る
- 業務用ミニアプリを企画から QA まで進めたい

## Prerequisites

| Skill | Status |
|-------|--------|
| to-prd | Required |
| frontend-design | Required — use instead of deprecated design-an-interface |
| web-artifacts-builder | Required |
| webapp-testing | Required — use instead of raw Playwright CLI |
| verification-before-completion | Required — use instead of deprecated QA |

## Workflow

### Step 1 — PRD

1. Capture conversation, constraints, and users.
2. Read and follow `to-prd` SKILL.md.
3. Output: PRD with scope, non-goals, and acceptance criteria.

### Step 2 — UI design

1. Read and follow `frontend-design` SKILL.md.
2. Produce UI direction before coding — do not skip to generic layouts.

### Step 3 — Build

1. Read and follow `web-artifacts-builder` SKILL.md.
2. Implement the smallest shippable version against the PRD.

### Step 4 — Browser QA

1. Read and follow `webapp-testing` SKILL.md.
2. Test critical paths, forms, and regressions in the browser.

### Step 5 — Verification

1. Read and follow `verification-before-completion` SKILL.md.
2. Run commands and capture evidence before calling it done.

## Done when

- PRD and working app exist
- Browser QA notes exist for critical flows
- Verification commands passed with output captured

## Do not

- Install deprecated `design-an-interface` or `qa` — use substitutes above
- Ship without webapp-testing on user-facing flows
