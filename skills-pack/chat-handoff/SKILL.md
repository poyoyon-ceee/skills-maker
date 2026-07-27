---
name: chat-handoff
description: >-
  Write a cross-PC chat handoff memo so work can continue on another machine without
  Cursor chat history. Creates or appends a dated 質疑応答M-D.MD at the repo root
  with conclusions, decisions, and open todos from the current session. Use ONLY
  when the user explicitly asks for a handoff / another-PC memo (e.g. "別PC用に残して",
  "引き継ぎ書いて", "質疑応答に落として", "続きは別端末でやるからまとめて",
  "このチャット持ち運べないから文書化して"). Do not use for ordinary session
  summaries into 備忘録.md (that is session-recap). Do not auto-run just because
  the user mentioned another PC in passing.
disable-model-invocation: true
---

# Chat Handoff

Cursor chat history stays on the local machine and does not sync via account.
When the user wants to continue on another PC, put the portable context into a
repo file — not into chat.

This skill is explicit-only. Never invent a handoff because the conversation
"feels done."

## Why this file exists

Another PC will not see this Cursor chat. The memo is the source of truth for
picking up later. Prefer short decisions over transcript dumps.

## Do not confuse with session-recap

| | This skill | `session-recap` |
|---|---|---|
| Trigger | Explicit handoff / 別PC / 引き継ぎ | Explicit 備忘録 / まとめて |
| Output | `質疑応答M-D.MD` at repo root | `備忘録.md` |
| Shape | Q&A or decision blocks with 結論・事実・次 | Short dated 目的/やったこと/次のTODO |

Never write handoff content into `備忘録.md`, `変更履歴.md`, or `CHANGELOG.md`.

## Step 1: Choose the output path

1. Use Japan time for "today."
2. Filename: `質疑応答M-D.MD` at the repository root
   - Month and day **without** zero-padding (match existing style: `質疑応答7-27.MD`)
   - Extension `.MD` (uppercase), same as existing files in this user's repos
3. If that file already exists, **read it fully** and **append** a new section.
   Do not overwrite or rewrite older Q blocks.
4. If a same-day file exists under a slightly different name (e.g. zero-padded),
   prefer the existing file and append there instead of creating a duplicate.

## Step 2: Extract only portable context

From the current conversation, keep:

- **結論** — the answer or decision in one short block
- **事実** — verified facts (separate from speculation)
- **推測** — only if useful; label 確信度（高・中・低）
- **実務 / 次アクション** — what to do on the other PC
- **未決・分岐** — open choices the other session must not re-litigate blindly
- **参照** — repo paths, related docs, key symbols

Drop:

- Full chat transcripts
- Pleasantries and process chatter
- Duplicate restatements of the same conclusion
- Secrets (API keys, passwords, tokens)

If the session was multi-topic, split into `## Qn. …` blocks (one decision per
section). If it was a single handoff topic, one Q block is enough.

## Step 3: Write the file

### New file template

```markdown
# 質疑応答 M/D

**対象:** <project / topic in one line>
**日付:** YYYY-MM-DD
**参加者:** ヒデさん / Tom
**目的:** 別PCでも続きできるよう、結論・決定・残タスクを残す（Cursorチャットは端末ローカルのため）

---

## Q1. <question or topic>

### 結論

<one short verdict>

### 事実

- ...

### 補足（推測は確信度つき）

- ...（確信度: 高/中/低）

### 実務 / 次アクション

1. ...
2. ...

### 未決

- ...

---

## 現状の合意（M/D時点）

| 項目 | 内容 |
|------|------|
| ... | ... |

---

## 参照

- `path/to/file` … why it matters
```

Omit empty subsections instead of filling with placeholders.

### Append template (file already exists)

Add below the last content (keep a `---` separator):

```markdown
---

## Qn. <new question or topic>（追記 YYYY-MM-DD HH:mm JST）

### 結論

...

### 事実

- ...

### 実務 / 次アクション

1. ...
```

Renumber `Qn` to continue from the highest existing Q number. Refresh or add a
「現状の合意」table only when decisions actually changed.

## Step 4: Confirm with the user

After writing:

1. Show the path (new vs append)
2. Paste the added section in chat
3. Ask whether to correct anything

If they request edits, fix the section just written — do not append a second copy.

## Quality bar

- Another PC opening only this file should know: what was decided, what is open, what to do next
- Prefer tables for "current agreement" snapshots
- Keep Tom's usual style: conclusion first, facts vs speculation separated, practical next steps
- Japanese body text unless the user writes in another language
