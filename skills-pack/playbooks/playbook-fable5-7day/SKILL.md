---
name: playbook-fable5-7day
description: >-
  Fable5 7-day business OS bootstrap playbook. Runs skill-creator, brainstorming,
  grill-me, verification, and systematic-debugging in order. Use when rebuilding
  personal workflows, reviving abandoned automations, or running a week-long
  Claude skills bootcamp through July 7.
disable-model-invocation: true
---

# Fable5 7-Day Playbook

業務棚卸し → Skill 作成 → 設計 → 穴埋め → QA → デバッグまで一気通貫。

## When to use

- 自分の業務 OS を作り直したい
- 過去に諦めた自動化を復活させたい
- Fable5 期間中に Skill 基盤を整えたい

## Prerequisites

| Skill | Status |
|-------|--------|
| skill-creator | Required — install if missing |
| brainstorming | Required — usually already global |
| grill-me | Required — usually already global |
| verification-before-completion | Required — use instead of deprecated QA |
| systematic-debugging | Required — usually already global |

If a required skill is missing, stop and tell the user which one to install.

## Workflow

### Step 1 — Inventory and skill-creator

1. Ask what workflows to automate this week.
2. Read and follow `skill-creator` SKILL.md.
3. Output: list of candidate custom skills with one-line purpose each.

### Step 2 — Brainstorming

1. Pick the highest-value workflow from Step 1.
2. Read and follow `brainstorming` SKILL.md.
3. Do not implement until design is approved.

### Step 3 — Grill Me

1. Read and follow `grill-me` SKILL.md on the approved design.
2. Resolve decision branches one at a time.

### Step 4 — Verification (QA substitute)

1. Read and follow `verification-before-completion` SKILL.md.
2. Run concrete checks before calling anything production-ready.
3. For UI flows, also use `webapp-testing` if applicable.

### Step 5 — Systematic debugging

1. When bugs or stuck automations appear, read and follow `systematic-debugging` SKILL.md.
2. No symptom patches until root cause is found.

## Done when

- At least one reusable custom skill exists or is drafted
- One workflow has an approved design
- Verification evidence exists for what ships this week

## Do not

- Skip brainstorming and jump to implementation
- Install deprecated `qa` skill — use verification-before-completion instead
