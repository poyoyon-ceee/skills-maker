---
name: playbook-lp-creative
description: >-
  LP, ad, and slide creative playbook. Runs marketing strategy, frontend-design,
  canvas-design, theme-factory, and pptx in order. Use for product launches,
  lead magnets, and seminar campaigns with unified visual tone. Starts with an
  adaptive proposal gate — wait for GO before creative or UI work.
disable-model-invocation: true
---

# LP / Ad / Slide Creative Playbook

訴求設計 → Web UI → ビジュアル → テーマ統一 → スライド。

## When to use

- 商品ローンチ、無料特典、セミナー募集の制作一式
- LP・広告・スライドのトンマナを揃えたい

## Prerequisites

| Skill | Status |
|-------|--------|
| marketingskills | Required — same pack (`skills-pack-marketing/marketingskills/`); messaging and channel |
| frontend-design | Required — from daily `skills-pack` (usually already global) |
| canvas-design | Required — from daily `skills-pack` |
| theme-factory | Required — from daily `skills-pack` |
| pptx | Required — from daily `skills-pack` |

## Adaptive proposal gate (do this first)

**HARD GATE:** Do not read step skills or start Workflow until the user approves an adaptive plan.
Exception: if the user already said `GO` / `通しで` with a clear step map (e.g. from `/route-playbook`), present the adapted Done-when briefly and proceed.

1. Restate offer, audience, and deliverables (LP / ads / slides).
2. Map each Workflow step to **必須** / **任意** / **スキップ** with one-line reason.
3. Recommend **チェックポイント** or **通し**.
4. Flag gaps (marketing pack missing → stop and tell user to install `skills-pack-marketing`).
5. Present and wait:

```markdown
### Adaptive plan
- Playbook: playbook-lp-creative
- Goal: <one line>
- Steps:
  - Step 1 Marketing frame — …
  - Step 2 LP / Web UI — …
  - Step 3 Visual assets — …
  - Step 4 Theme unification — …
  - Step 5 Slides — …
- Mode: チェックポイント | 通し
- Prerequisites: OK | <gaps>
- Done-when (adapted): <only non-skipped steps>
```

Reply: `GO` / `通しで` / `プラン修正: …`

After approval, redefine "Done when" to the adapted list.

## Workflow

### Step 1 — Marketing frame

1. Define offer, audience, objection, and CTA.
2. Read relevant skill from `marketingskills` repo.
3. Output: one-page creative brief.

### Step 2 — LP / Web UI

1. Read and follow `frontend-design` SKILL.md.
2. Build or specify the landing page structure and copy placement.

### Step 3 — Visual assets

1. Read and follow `canvas-design` SKILL.md.
2. Create banners, social visuals, or hero art aligned to the brief.

### Step 4 — Theme unification

1. Read and follow `theme-factory` SKILL.md.
2. Apply consistent colors, typography, and spacing across assets.

### Step 5 — Slides

1. Read and follow `pptx` SKILL.md.
2. Build deck using the same theme and brief.

## Done when

- Creative brief exists
- LP spec or implementation exists
- At least one visual asset and slide deck outline exist
- All outputs share one theme
- (After adaptive gate: only approved non-skipped steps apply)

## Do not

- Start with visuals before offer and CTA are clear
- Use generic AI-template aesthetics when frontend-design says otherwise
- Skip the adaptive proposal gate unless user already approved a plan
