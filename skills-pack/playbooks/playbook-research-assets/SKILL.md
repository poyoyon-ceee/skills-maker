---
name: playbook-research-assets
description: >-
  Research assetization playbook. Runs notebooklm integration, obsidian-vault,
  content-research-writer, and optional terminology cleanup. Use when turning
  scattered notes, customer feedback, and course materials into reusable knowledge.
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
| obsidian-vault | Required if using Obsidian |
| content-research-writer | Required |
| ubiquitous-language | Optional — skip deprecated; do glossary inline if needed |

## Workflow

### Step 1 — Source map

1. List sources: NotebookLM notebooks, Obsidian vault paths, files, URLs.
2. Define the topic boundary and intended reuse (article, course, sales, ops).

### Step 2 — NotebookLM (if applicable)

1. Read and follow `notebooklm` SKILL.md (in `notebooklm-skill/` folder).
2. Extract cross-source insights for the topic.

### Step 3 — Obsidian (if applicable)

1. Read and follow `obsidian-vault` SKILL.md.
2. Organize notes with links, tags, and MOC if useful.

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

## Do not

- Copy everything into one giant note without structure
- Require NotebookLM or Obsidian when user only has flat files — adapt Steps 2–3
