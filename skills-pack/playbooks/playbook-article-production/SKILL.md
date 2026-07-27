---
name: playbook-article-production
description: >-
  Article and post production playbook. Runs content research, doc co-authoring,
  edit-article, and optional marketing polish in order. Use for X posts, note
  articles, newsletters, and seminar announcement copy. Starts with an adaptive
  proposal gate — wait for GO before researching or drafting.
disable-model-invocation: true
---

# Article Production Playbook

調査 → 共同執筆 → 構造編集 → （任意）訴求調整。

## When to use

- X 記事、note、メルマガ、セミナー告知文を量産したい
- リサーチから公開原稿まで一気通貫で進めたい

## Prerequisites

| Skill | Status |
|-------|--------|
| content-research-writer | Required |
| doc-coauthoring | Required |
| edit-article | Required — usually already global |
| marketingskills | Optional — only if `skills-pack-marketing` is installed; CTA and channel fit |

## Adaptive proposal gate (do this first)

**HARD GATE:** Do not read step skills or start Workflow until the user approves an adaptive plan.
Exception: if the user already said `GO` / `通しで` with a clear step map (e.g. from `/route-playbook`), present the adapted Done-when briefly and proceed.

1. Restate topic, audience, and channel.
2. Map each Workflow step to **必須** / **任意** / **スキップ** with one-line reason.
3. Recommend **チェックポイント** or **通し**.
4. Flag gaps (marketing pack missing → skip Step 4).
5. Present and wait:

```markdown
### Adaptive plan
- Playbook: playbook-article-production
- Goal: <one line>
- Steps:
  - Step 1 Research — …
  - Step 2 Co-authoring — …
  - Step 3 Edit — …
  - Step 4 Marketing polish — …
- Mode: チェックポイント | 通し
- Prerequisites: OK | <gaps>
- Done-when (adapted): <only non-skipped steps>
```

Reply: `GO` / `通しで` / `プラン修正: …`

After approval, redefine "Done when" to the adapted list.

## Workflow

### Step 1 — Research

1. Confirm topic, audience, and goal.
2. Read and follow `content-research-writer` SKILL.md.
3. Output: structured outline with sources.

### Step 2 — Co-authoring

1. Read and follow `doc-coauthoring` SKILL.md.
2. Produce a first draft with reader-test checkpoints.

### Step 3 — Edit

1. Read and follow `edit-article` SKILL.md.
2. Reorder sections by information dependencies; tighten prose.

### Step 4 — Marketing polish (optional)

1. If distribution matters **and** `skills-pack-marketing` is installed, read the relevant skill under `marketingskills/`.
2. If the marketing pack is not installed, skip this step or ask the user to install it from `skills-pack-marketing/`.
3. Adjust hook, CTA, and channel-specific variants.

## Done when

- Publish-ready draft exists
- Three title options provided
- Sources or claims flagged where uncertain
- (After adaptive gate: only approved non-skipped steps apply)

## Do not

- Skip research and write from memory when facts matter
- Only proofread grammar when structure is the main problem — use edit-article
- Skip the adaptive proposal gate unless user already approved a plan
