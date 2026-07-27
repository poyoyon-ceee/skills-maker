---
name: playbook-research-assets
description: >-
  Research assetization playbook. Runs notebooklm integration, obsidian-vault,
  obsidian-markdown, json-canvas, content-research-writer, and optional
  terminology cleanup. Use when turning scattered notes, customer feedback, and
  course materials into reusable knowledge. Starts with an adaptive proposal
  gate — wait for GO before querying NotebookLM or rewriting the vault.
disable-model-invocation: true
---

# Research Assets Playbook

NotebookLM / Obsidian / リサーチ → 再利用可能なナレッジ資産化。

## When to use

- 顧客の声、教材、過去記事、社内メモを横断整理したい
- 散らかったナレッジを検索・再利用できる形にしたい

## Prerequisites

| Skill | Status |
|-------|--------|
| notebooklm | Required if using NotebookLM sources (folder: notebooklm-skill) |
| obsidian-vault | Required if using Obsidian (vault path: `D:\vault`) |
| obsidian-markdown | Use when writing or fixing Obsidian note syntax (callouts, properties, embeds) |
| json-canvas | Use when creating or updating `.canvas` overview maps (`D:\vault\canvas\`) |
| content-research-writer | Required |
| ubiquitous-language | Optional — skip deprecated; do glossary inline if needed |

## Adaptive proposal gate (do this first)

**HARD GATE:** Do not read step skills or start Workflow until the user approves an adaptive plan.
Exception: if the user already said `GO` / `通しで` with a clear step map (e.g. from `/route-playbook`), present the adapted Done-when briefly and proceed.

1. Restate the topic boundary and intended reuse.
2. Map each Workflow step to **必須** / **任意** / **スキップ** with one-line reason.
3. Recommend **チェックポイント** or **通し**.
4. Flag gaps (no NotebookLM → skip Step 2; no Obsidian → skip Step 3).
5. Present and wait:

```markdown
### Adaptive plan
- Playbook: playbook-research-assets
- Goal: <one line>
- Steps:
  - Step 1 Source map — …
  - Step 2 NotebookLM — …
  - Step 3 Obsidian — …
  - Step 4 Research synthesis — …
  - Step 5 Terminology — …
- Mode: チェックポイント | 通し
- Prerequisites: OK | <gaps>
- Done-when (adapted): <only non-skipped steps>
```

Reply: `GO` / `通しで` / `プラン修正: …`

After approval, redefine "Done when" to the adapted list.

## Workflow

### Step 1 — Source map

1. List sources: NotebookLM notebooks, Obsidian vault paths, files, URLs.
2. Define the topic boundary and intended reuse (article, course, sales, ops).

### Step 2 — NotebookLM (if applicable)

1. Read and follow `notebooklm` SKILL.md (in `notebooklm-skill/` folder).
2. Extract cross-source insights for the topic.

### Step 3 — Obsidian (if applicable)

1. Read and follow `obsidian-vault` SKILL.md — search, create, organize notes; update Index notes.
2. When writing note bodies, read and follow `obsidian-markdown` SKILL.md for callouts, frontmatter, embeds.
3. When a visual overview helps, read and follow `json-canvas` SKILL.md; save under `D:\vault\canvas\`.

### Step 4 — Research synthesis

1. Read and follow `content-research-writer` SKILL.md.
2. Produce structured brief: claims, quotes, gaps, recommended next uses.

### Step 5 — Terminology (optional)

1. If multiple docs use inconsistent terms, produce a mini glossary in the output.
2. Do not require deprecated `ubiquitous-language` skill.

## Done when

- Source map and synthesis doc exist
- Reusable assets identified (articles, FAQs, talk tracks)
- Terminology inconsistencies noted or resolved
- (After adaptive gate: only approved non-skipped steps apply)

## Do not

- Copy everything into one giant note without structure
- Require NotebookLM or Obsidian when user only has flat files — adapt Steps 2–3
- Skip the adaptive proposal gate unless user already approved a plan
