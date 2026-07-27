---
name: route-playbook
description: >-
  Playbook router. Matches the user request to the best playbook, proposes an
  adaptive step plan, and waits for GO before handing off. Use when the user is
  unsure which playbook to run, says "どのplaybook", "route", "オーケストレーター",
  "台本を選んで", or describes a multi-step job without naming a playbook.
disable-model-invocation: true
---

# Route Playbook

要求を見て **どの playbook をどう走らせるか** を提案する。実行はしない。

## When to use

- どの `/playbook-*` を呼ぶか分からない
- 「記事書いて」「見積まとめて」「社内ツール作って」など、複数スキルが絡みそう
- 既存の `/playbook-*` が合っているか確認したい

## Hard gate

**ユーザーが GO するまで、どの playbook / ステップスキルも読まない・実行しない。**

## Catalog (choose from this table — do not invent playbooks)

| Playbook | One-line fit | Pack |
|----------|--------------|------|
| `playbook-document-data` | PDF / Word / Excel の取込・比較表・レポート。任意で Google Docs/Sheets/Drive | daily |
| `playbook-article-production` | X / note / メルマガ / 告知文。リサーチ→執筆→編集 | daily |
| `playbook-mini-webapp` | 社内ツール・フォーム・簡易ダッシュボードを PRD→実装→QA | daily |
| `playbook-app-improvement` | 既存アプリの再発バグ・複雑化・改善 | daily |
| `playbook-research-assets` | NotebookLM / Obsidian / 散在メモのナレッジ資産化 | daily |
| `playbook-fable5-7day` | 業務 OS・カスタムスキル基盤の一気通貫ブートストラップ | daily |
| `playbook-lp-creative` | LP・広告・スライドの訴求〜トンマナ統一制作 | **marketing**（未導入なら候補から外すか導入を促す） |

## Workflow

### Step 1 — Intake

1. Restate the user goal in one sentence.
2. Note inputs (files, URLs, repos) and constraints (deadline, Google, no marketing pack, etc.).

### Step 2 — Match

1. Pick **one primary** playbook from the catalog using When-to-use fit.
2. Pick **one alternate** (or say none).
3. If marketing pack is required and not installed, say so; do not pretend `playbook-lp-creative` will work.

### Step 3 — Adaptive sketch (lightweight)

For the **primary** only, sketch steps as 必須 / 任意 / スキップ with one-line reasons.
Do **not** open the playbook SKILL.md yet unless the user already named that playbook and asked for a deep plan.

### Step 4 — Present and wait

Use this exact structure:

```markdown
### Route proposal
- Goal: <one line>
- Primary: `/playbook-<name>` — <why>
- Alternate: `/playbook-<name>` | none — <why>
- Adaptive sketch (primary):
  - Step … — 必須|任意|スキップ — <why>
- Mode recommendation: チェックポイント | 通し
- Pack / prerequisite gaps: <none | list>
- Next: reply `GO` (run primary's adaptive gate) / `代替で` / `プラン修正: …` / `playbook不要、個別スキルで`
```

### Step 5 — After GO

1. Read and follow the **primary** playbook's `SKILL.md`.
2. That playbook's **Adaptive proposal gate** runs next (full step map + another GO unless user already said `通しで`).
3. If user said `GO 通しで`, pass that through so the playbook may skip a second pause after presenting its adapted Done-when.

## Done when

- Primary (+ optional alternate) proposed with reasons
- User chose GO / alternate / revise / no-playbook
- On GO: handoff to the chosen playbook skill started

## Do not

- Start extracting files, writing code, or reading step skills before GO
- Auto-pick marketing playbooks when the marketing pack is missing
- Chain multiple playbooks in one go without saying so and getting approval
