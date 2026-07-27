---
name: playbook-document-data
description: >-
  Document and data wrangling playbook. Runs pdf, docx, xlsx extraction and
  structuring, with optional Google Workspace (gws CLI) for Docs, Sheets, and
  Slides. Use for invoices, quotes, contracts, spreadsheets, and Google Drive files.
  Starts with an adaptive proposal gate — wait for GO before extracting.
disable-model-invocation: true
---

# Document & Data Playbook

PDF / Word / Excel 取込 → 構造化 → 比較表・レポート。Google 資料は Phase 2。

## When to use

- 見積書、請求書、契約書、資料 PDF の整理
- バラバラの Excel / Word を比較表やレポートにまとめたい
- **Google Docs / Sheets / Slides / Drive 上の資料を整理したい**

## Prerequisites

### Phase 1 — file skills (required)

| Skill | Status |
|-------|--------|
| pdf | Required |
| docx | Required |
| xlsx | Required |

### Phase 2 — Google Workspace (optional)

| Tool | Status |
|------|--------|
| gws CLI (`@googleworkspace/cli`) | Optional — needs one-time OAuth |

**Do not use Firecrawl** unless the user explicitly asks for web scraping.

If Phase 1 skills are missing, stop and report which to install.
If user needs Google Docs/Sheets/Slides, confirm `gws auth login` is done before Phase 2.

## Adaptive proposal gate (do this first)

**HARD GATE:** Do not read step skills (`pdf` / `docx` / `xlsx` / gws) or start Workflow until the user approves an adaptive plan.
Exception: if the user already said `GO` / `通しで` with a clear step map (e.g. from `/route-playbook`), present the adapted Done-when briefly and proceed.

1. Restate the goal and list inputs (paths, Google IDs/URLs).
2. Map each Workflow step to **必須** / **任意** / **スキップ** with one-line reason.
3. Recommend **チェックポイント** or **通し**.
4. Flag gaps (missing file skills, `gws` auth).
5. Present and wait:

```markdown
### Adaptive plan
- Playbook: playbook-document-data
- Goal: <one line>
- Steps:
  - Step 1 Intake — …
  - Step 2 Extract (local) — … (which of pdf/docx/xlsx)
  - Step 3 Extract (Google) — …
  - Step 4 Structure — …
- Mode: チェックポイント | 通し
- Prerequisites: OK | <gaps>
- Done-when (adapted): <only non-skipped steps>
```

Reply: `GO` / `通しで` / `プラン修正: …`

After approval, redefine "Done when" to the adapted list (skipped steps do not block completion).

## GWS setup (one-time)

1. Install: `npm install -g @googleworkspace/cli`
2. Auth: `gws auth setup` then `gws auth login -s drive,sheets,docs`
3. Verify: `gws drive files list --params '{"pageSize": 3}'`

Skills ship inside the gws repo — install helpers if needed:

```bash
npx skills add https://github.com/googleworkspace/cli/tree/main/skills/gws-docs
npx skills add https://github.com/googleworkspace/cli/tree/main/skills/gws-sheets
npx skills add https://github.com/googleworkspace/cli/tree/main/skills/gws-drive
```

## Workflow

### Step 1 — Intake

1. List input sources: local files and/or Google file IDs/URLs.
2. Classify each input: pdf, docx, xlsx, google-doc, google-sheet.

### Step 2 — Extract (local files)

1. For PDF: read and follow `pdf` SKILL.md.
2. For Word: read and follow `docx` SKILL.md.
3. For Excel: read and follow `xlsx` SKILL.md.

### Step 3 — Extract (Google — Phase 2)

1. Only if `gws` is authenticated and user confirmed.
2. Use `gws docs`, `gws sheets`, or `gws drive` commands (or gws-* skills if installed).
3. Export or read content, then structure like Step 4.

### Step 4 — Structure

1. Merge extracted data into tables or report sections.
2. Flag missing fields, OCR issues, or inconsistent numbers.

## Done when

- Structured summary or comparison table exists
- Source files mapped to extracted fields
- Anomalies and confidence gaps are listed
- (After adaptive gate: only approved non-skipped steps apply)

## Do not

- Suggest Firecrawl unless user explicitly requests competitor web scraping
- Assume GWS works without `gws auth login`
- Mix Phase 2 failure with Phase 1 — complete local file skills first
- Skip the adaptive proposal gate unless user already approved a plan
