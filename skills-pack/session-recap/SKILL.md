---
name: session-recap
description: >-
  Use when the user explicitly asks to record this session as a dated 備忘録
  entry (e.g. "備忘録に残して", "セッションを記録して", "まとめて",
  "このやり取りを記録して", "今回の内容を書いといて"). Do not use for a
  引継ぎ書 or handoff to another chat, person, or machine (that is chat-handoff).
  This is NOT a code-change changelog. Do not auto-run because a conversation
  feels finished.
disable-model-invocation: true
catalog-section: 5
catalog-summary: 今の会話を備忘録.mdの日付エントリにする（決定・調査・次のTODO）。コード変更履歴用の変更履歴.mdには書かない
catalog-when: 「まとめて」「備忘録に残して」「このやり取りを記録して」と明示されたとき。引継ぎは /chat-handoff
---

# Session Recap

Turns the current conversation into one dated entry in `備忘録.md`. It exists because `変更履歴.md`/`CHANGELOG.md` files track *code* changes, but a lot of valuable sessions produce decisions, research, and things-to-remember with no diff at all — those need a home too. Never touch `変更履歴.md` or any release-notes-style file; this skill only ever writes to `備忘録.md`.

Only run this when the user explicitly asks for it. Don't infer "the conversation feels done, let me log it" — that's noisy and this skill is manual-only for a reason.

## Do not confuse with chat-handoff

| | This skill | `chat-handoff` |
|---|---|---|
| Trigger | 備忘録に残して / セッションを記録して / まとめて | 引き継いで / 引継ぎ書 / 別チャット・別担当・別マシン |
| Output | Dated entries in `備忘録.md` | One `引継ぎ書.md` |
| Shape | Append-only memory aid | Latest state to resume from |

「まとめて」alone stays here. Combined with 引継ぎ / 別チャット / 別担当 / 別マシン, use `chat-handoff` instead.

If the user explicitly asks for both a 備忘録 and a 引継ぎ書, run **both** skills, each to its own file.

Never write recap content into `引継ぎ書.md`.

## Step 1: Find or decide the output file

Search, in order, for an existing `備忘録.md`:

1. Repository root
2. `docs/備忘録.md`

If one exists, read it fully. Note its heading style (date format, whether entries use `##` or `###`, whether there's a top-level `# 備忘録` title, language) and match it — don't impose a different format on an existing file.

If none exists, create `備忘録.md` at the repository root using the template in Step 3 as-is.

If you find a `変更履歴.md`, `CHANGELOG.md`, or `HISTORY.md` instead, that is a *different* file for a *different* purpose (code-change history, often version-numbered) — do not write session recap content into it, and do not treat its presence as satisfying this skill's search. Only `備忘録.md` counts.

## Step 2: Draft the entry from the actual conversation

Reread the session and pull out only what's real — don't pad it out to look thorough. Skip any of the four fields below if there's genuinely nothing to say for it (e.g. no numeric result), rather than writing a filler sentence.

- **目的**: why this session happened / what question or problem started it
- **やったこと**: the concrete actions taken or decisions reached, as a short bullet list
- **結果**: outcomes, especially anything measurable (counts, before/after numbers, pass/fail). Omit if there's nothing quantitative or concrete to report.
- **次のTODO**: anything explicitly left open, deferred, or that the user should remember to pick up next time. Omit if nothing is actually pending.

Keep it terse. This is a memory aid for the user's future self, not a report for an audience — favor short bullets over prose.

## Step 3: Write the entry

Insert the new entry at the **top** of the file's entry list (below any `# 備忘録` title line, but above all previous entries — most recent first). Never edit or remove existing entries.

Default template if the file is new or has no established style to match:

```markdown
# 備忘録

## YYYY-MM-DD

**目的:** ...

**やったこと:**
- ...

**結果:** ...

**次のTODO:**
- ...
```

Use the actual current date. If the file already had its own heading/date style, follow that instead of this default.

## Step 4: Confirm with the user

After writing, show the exact entry you added (as a markdown snippet in chat) and briefly say where it went (new file vs. appended to existing, and the path). Ask if anything should be corrected or removed — this is their personal record, so accuracy matters more than speed here. If they ask for changes, edit the entry you just added, don't re-append a second one.
