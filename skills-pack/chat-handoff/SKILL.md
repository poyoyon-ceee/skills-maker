---
name: chat-handoff
description: >-
  Use when the user explicitly asks to hand off work to another chat, person,
  or machine (e.g. "引き継いで", "引継ぎ書を作って", "引継ぎ書を更新して",
  "別PC用に残して", "続きは別チャットで", "質疑応答に落として",
  "このチャット持ち運べないから文書化して"). Do not use for a dated
  備忘録 entry (that is session-recap). Do not auto-run because a conversation
  feels finished or because another machine was mentioned in passing.
disable-model-invocation: true
catalog-section: 5
catalog-summary: 別チャット・別担当・別マシン向けに、最新状態の引継ぎ書.mdを1ファイルで更新する
catalog-when: 「引き継いで」「引継ぎ書を作って／更新して」と明示されたとき。通常の備忘録は /session-recap
---

# Chat Handoff

Keep a **single latest-state** `引継ぎ書.md` so another chat, person, or machine can resume. This is not a diary. Dated files are a legacy shape to migrate from, not the default.

Run only on an explicit handoff request. Do not infer that the conversation is over.

## Do not confuse with session-recap

| | This skill | `session-recap` |
|---|---|---|
| Trigger | 引き継いで / 引継ぎ書 / 別チャット・別担当・別マシン | 備忘録に残して / セッションを記録して / まとめて |
| Output | One `引継ぎ書.md` (or a path the user named) | Dated entries in `備忘録.md` |
| Shape | Latest state to resume from | Append-only memory aid |

「まとめて」alone is `session-recap`. Combined with 引継ぎ / 別チャット / 別担当 / 別マシン, it is this skill.

If the user explicitly asks for both a 引継ぎ書 and a 備忘録, run **both** skills, each to its own file.

If the request is still ambiguous after reading the conversation and existing files, ask. Do not guess.

Never write handoff content into `備忘録.md`, `変更履歴.md`, or `CHANGELOG.md`.

## Step 1: Choose the target project

Resolve in this order:

1. The target the user named.
2. The target that is already clear from this conversation, the workspace, or project instructions.
3. If none is clear, or several candidates remain, ask.

Do not treat the current working directory as the project root by default. A nested folder, a pack directory, or a monorepo subfolder is not automatically the handoff target.

## Step 2: Choose the output path

Prefer a path the user named. If they did not, use `引継ぎ書.md` at the target project's root.

If more than one `引継ぎ書.md` could apply, ask.

## Step 3: Read before writing

Read:

- The existing `引継ぎ書.md`, if any
- This conversation
- Related real files that the next session will need
- README or, if none, the project's other entry document
- Dated handoff-like files only to decide whether Step 7 applies

Carry forward unresolved items, constraints, next work, unresolved failures, and cautions still needed to prevent repeats. Do not drop them because they are old.

Lasting decisions, findings, and lessons belong in their canonical docs when the destination is clear. In the handoff, leave a short caution plus a link. If the destination is not clear, keep them under **未整理事項**. Do not delete them.

Write only what actually exists. Label confirmed facts, earlier reports, and speculation separately.

## Step 4: Update the one handoff file

Rewrite `引継ぎ書.md` to the **current** resume state. Do not append a new dated file each time. Do not stack the full history.

Do not blank existing content and replace it blindly. Merge: keep still-open items, unresolved failures, and cautions still needed to prevent repeats. Drop only what the current evidence shows is done or obsolete.

**失敗・試したが採用しなかった方法** is required. Never omit it. Other sections: omit when empty instead of filling placeholders.

Record a failure or a rejected approach only when it actually happened. Do not invent one. If there was nothing to record, write exactly `今回、記録対象の失敗なし` under the heading.

When there was a failure or a tried-but-rejected approach, record:

- What was attempted
- The method tried and the conditions
- The problem or error
- Cause, labeled 確認済み or 推測
- Remedy and result, labeled 解決 / 回避 / 未解決
- What the next person should avoid, and when a retry is allowed

Keep a resolved failure if it is still needed to prevent a repeat. Do not accumulate mere operation logs.

If the lasting lesson has a clear canonical home, move it there and leave only a short caution plus a link in this file.

```markdown
# 引継ぎ書

**最終更新:** YYYY-MM-DD HH:mm TZ

## 目的・重要な合意

- ...

## 現在地

...

## 実行内容と結果

- ...

## 失敗・試したが採用しなかった方法

今回、記録対象の失敗なし

## 未確認・未実施・未解決

- ...

## 次にする作業

1. ...

## 正本・成果物

- [label](relative/path) — why it matters

## 未整理事項

- ...
```

When recording a real failure, replace the none-line with entries of this shape:

```markdown
### <短い見出し>

- **何をしようとしたか:** ...
- **試した方法・発生条件:** ...
- **起きた問題やエラー:** ...
- **原因:** ...（確認済み / 推測）
- **対処と結果:** ...（解決 / 回避 / 未解決）
- **次の担当が避けること / 再挑戦できる条件:** ...
```

`TZ` is an explicit timezone, not a local clock with the zone omitted.

## Step 5: Keep the README link in sync

Treat README link check as part of every handoff-file update.

- If README exists: add a link to `引継ぎ書.md` when missing, replace a stale dated-file link, leave a healthy fixed link alone.
- If README does not exist: use the existing entry document the same way.
- If there is no entry document: create a short README whose job is to point at `引継ぎ書.md`.

Do not rewrite the rest of README unless the user asked to introduce or update the handoff workflow.

In Obsidian vaults, follow the vault's existing link style (wikilinks if that is what the project uses). Elsewhere, use normal Markdown links.

## Step 6: Introduce the workflow only when asked

When the user asks to **introduce or update** handoff operations in the project, also:

- In README, briefly state the skill name `chat-handoff`, what it is for, how to find it, and a link to `引継ぎ書.md`.
- If a linkable copy of the skill lives inside the project, use a relative link. If the skill lives outside the project, do not invent a broken relative link or a machine-specific absolute path. With no portable public URL, write the skill name and how to find it (available skills / `chat-handoff`).
- Put execution conditions in existing AI instruction files (`AGENTS.md`, `CLAUDE.md`, or the project's equivalent). A README skill link is not enough.
- Do not copy this skill body into README or instruction files.

When the user only asked to update `引継ぎ書.md`, do Step 5 (link check) and stop. Do not rebuild project instructions.

Suggested execution condition (adapt to the file's existing style; do not paste this skill):

```markdown
When the user explicitly asks to hand off work or to create/update 引継ぎ書, follow the `chat-handoff` skill.
When they ask to record a 備忘録, follow `session-recap`.
Do not write either file just because a conversation appears finished.
```

## Step 7: Migrate dated handoff files only when they exist

If dated handoff files are present (`質疑応答M-D.MD`, `引継ぎ書-YYYY-MM-DD.md`, and similar), they are **candidates**, not automatic deletes.

- Confirm they are handoff memos by content (resume state, decisions, next work, failures). Do not treat design notes, research docs, or similarly named setup guides as handoff files.
- If several candidates exist, merge still-needed decisions, unresolved items, unresolved failures, and repeat-prevention cautions into `引継ぎ書.md` after checking them. Ask when the right merge is unclear.
- Do not overwrite `引継ぎ書.md` unconditionally.
- Make the pre-migration text recoverable **before** removing the old file: git history if the project is a git repo; otherwise a permitted location **outside** the project, then report that location. If neither is available, stop. Do not delete.
- After a safe migration, point README and other references at `引継ぎ書.md`. Do not leave the old handoff file or a backup copy inside the project.

Skip this step when there is no dated handoff file.

## Step 8: Verify and report

After writing, report:

- Target project and output path (created vs updated)
- README / entry-doc link status
- What was preserved (unresolved items, unresolved failures, repeat-prevention cautions, unsorted items, migrated sources)
- Canonical docs updated, if any
- Anything still unconfirmed

Show the written `引継ぎ書.md` (or the changed sections) in chat. If the user asks for edits, change that same file. Do not create a second copy.

## Quality bar

- Someone opening only `引継ぎ書.md` should know the purpose, where things stand, what failed or was rejected, what is open, and what to do next.
- Prefer short bullets over transcripts. Do not accumulate mere operation logs.
- Do not put secrets (API keys, passwords, tokens) in the handoff.
