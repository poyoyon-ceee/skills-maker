---
name: "00"
description: >-
  Use when the user explicitly starts the current message with /00 or $00 to
  skip Superpowers for this turn only. Do not use when /00 appears only inside
  quotes, code, or explanation.
disable-model-invocation: true
---

# 00

One-turn Superpowers bypass. Explicit leading `/00` (Codex mention: `$00`) only.

## Trigger

The **current user message** matches `^\s*(?:\/|\$)00(?:\s|$)` as a leading command.

Does **not** trigger when `/00` appears only in quotes, 引用, code/コード fences, or running text.

## This turn

1. Do not follow `using-superpowers`.
2. Do not auto-select Superpowers-required workflows: `brainstorming`, `writing-plans`, `test-driven-development` / TDD, `systematic-debugging`, code review, `verification-before-completion`, subagents, worktrees, `executing-plans`.
3. Process the remainder of the message normally.
4. Non-Superpowers task skills remain available if needed or explicitly requested.
5. System, developer, safety, permission, and app-specific rules stay in force.

## Empty command

If there is no request body (`/00` only), 依頼本文がない — 作業を開始しない. Ask what to do.

## Persistence

This bypass lasts until this reply finishes. Do not persist flags, config, or session variables. 次のユーザーメッセージへは引き継がない / 保存しない. The next user message returns to normal Superpowers and must repeat `/00` to bypass again.
