# promote-skill Claude 対応 — 実装計画

> **For agentic workers:** タスク順に実装。ユーザーが commit を頼むまで commit しない。

**Goal:** Claude Code でも `/promote-skill` の Gate 1→2 が完結する（spec: `docs/superpowers/specs/2026-08-09-promote-skill-claude-design.md`）

**Architecture:** SKILL 手順を IDE 中立化 + スクリプトのソース探索に `~/.claude/skills` を追加。配置 root（cursorOnly）は変えない。

**Tech stack:** Markdown skill + PowerShell / bash

---

### Task 1: SKILL.md 更新

**Files:**
- Modify: `skills-pack/promote-skill/SKILL.md`

- [ ] 宛先表を3行（agents / cursor / claude）に
- [ ] Cursor 固有3件の説明は残すが、「promote 自身は Claude でも使う」と明記
- [ ] スクリプト起動を自己解決の探索順に書き換え（固定 `~/.cursor/...` 削除）
- [ ] 禁止事項: agents∩cursor のみ。agents∩claude 可を明記

### Task 2: promote-to-pack スクリプト

**Files:**
- Modify: `skills-pack/promote-skill/scripts/promote-to-pack.ps1`
- Modify: `skills-pack/promote-skill/scripts/promote-to-pack.sh`

- [ ] ソース探索に `~/.claude/skills` を追加（agents → cursor → claude）
- [ ] コメント・エラーメッセージも3 root 記載

### Task 3: ドキュメント注記

**Files:**
- Modify: `skills-pack/INSTALL.md`
- Modify: `skills一覧.md`

- [ ] promote-skill は Claude でも利用可・Gate 1 に `~/.claude` あり、を短く追記
- [ ] cursorOnly 3件の配置説明は維持（promote の install 先は従来どおり）

### Task 4: 配布同期

- [ ] `install.ps1` 相当で promote-skill を cursor へ、`install-claude.ps1` で claude へ反映（または当該フォルダだけ Copy-Item）
- [ ] 検証: SKILL に固定パス無し、ps1/sh に `.claude` あり、cursorOnly リスト不変
