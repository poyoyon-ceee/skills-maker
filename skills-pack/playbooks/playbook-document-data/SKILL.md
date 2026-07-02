---
name: playbook-document-data
description: >-
  Document and data wrangling playbook. Runs pdf, docx, xlsx extraction and
  structuring, with optional Google Workspace (gws CLI) for Docs, Sheets, and
  Slides. Use for invoices, quotes, contracts, spreadsheets, and Google Drive files.
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

## Do not

- Suggest Firecrawl unless user explicitly requests competitor web scraping
- Assume GWS works without `gws auth login`
- Mix Phase 2 failure with Phase 1 — complete local file skills first
