# promote-skill Claude Code 対応

日付: 2026-08-09  
状態: approved  
範囲: Approach A-2（`promote-skill` のみ。`chat-handoff` / `skill-creator` / `cursorOnly` 枠は不変）

## 問題

`promote-skill` は Cursor 専用前提で書かれている。

- スクリプト起動パスが `~/.cursor/skills/promote-skill/scripts/...` 固定
- Gate 1 宛先が `~/.agents` / `~/.cursor` のみ → Claude Code で作ったスキルを `~/.claude` に載せられない
- `promote-to-pack` のソース探索に `~/.claude/skills` が無い

一方 `install-claude.ps1` は `promote-skill` を除外しておらず、Claude には既にコピーされる。中身が Cursor 前提のままなので半端。

## 目標

Claude Code でも `/promote-skill` の Gate 1 → Gate 2 が完結する。Cursor 既存フローは回帰させない。

## 非目標

- `chat-handoff` の IDE 中立化
- `skill-creator` を Claude に入れる（公式と重複のため除外のまま）
- `promote-skill` を `cursorOnly` から外して `~/.agents` へ移す
- `install.ps1` の Cursor 固有3件枠の解体

## Gate 1 宛先

| 条件 | 宛先 |
|------|------|
| 通常（IDE 非依存） | `~/.agents/skills/<name>/` |
| Cursor 固有（`.cursor` パス・Cursor UI 前提） | `~/.cursor/skills/<name>/` |
| Claude Code で今すぐ使う | `~/.claude/skills/<name>/` |

ルール:

- **禁止:** `~/.agents` と `~/.cursor` の両方に同名を置く（Cursor 二重登録）
- **可:** `~/.agents` と `~/.claude` の併置（別ツールが読む）
- 迷ったら `~/.agents`。Claude でもすぐ使うなら `~/.claude`（必要なら agents にも）

## スクリプト起動（自己解決）

`SKILL.md` から `~/.cursor/...` 固定を削除。実行時に次の順で `promote-to-pack.(ps1|sh)` を探す:

1. 今ロードしている `promote-skill` フォルダの `scripts/`（隣）
2. `~/.claude/skills/promote-skill/scripts/`
3. `~/.cursor/skills/promote-skill/scripts/`
4. `~/.agents/skills/promote-skill/scripts/`（将来用）

見つからなければ止めて報告。勝手に別パスへリトライしない。

## promote-to-pack ソース探索

Gate 1 済みスキルの探索順:

1. `~/.agents/skills/<name>/`
2. `~/.cursor/skills/<name>/`
3. `~/.claude/skills/<name>/` ← 追加

先に見つかった方を正とする（agents 優先は従来どおり）。

## promote-skill 自身の配置（不変）

- Cursor: `~/.cursor/skills/promote-skill/`（`install.ps1`）
- Claude: `~/.claude/skills/promote-skill/`（`install-claude.ps1`）

## 変更ファイル

| ファイル | 内容 |
|----------|------|
| `skills-pack/promote-skill/SKILL.md` | 宛先3択・スクリプト自己解決・禁止事項の明確化 |
| `skills-pack/promote-skill/scripts/promote-to-pack.ps1` | `~/.claude/skills` をソース探索に追加 |
| `skills-pack/promote-skill/scripts/promote-to-pack.sh` | 同上 |
| `skills-pack/INSTALL.md` | promote は Claude でも可・宛先に `~/.claude` あり（短注記） |
| `skills一覧.md` | 同上（短注記） |

## 成功条件

1. Claude 上で Gate 1 宛先に `~/.claude` を選べる
2. Gate 2 が `~/.claude` 上のスキルをソースに pack へ書ける
3. Cursor 既存フロー（agents / cursor）は回帰しない
4. `chat-handoff` / `skill-creator` / `cursorOnly` リストは不変

## 検証

- SKILL.md に `~/.cursor/skills/promote-skill/scripts` の固定パスが残っていない
- ps1/sh の `$globalRoots` / 探索ループに `.claude/skills` がある
- `install.ps1` の `$cursorOnlySkills` に `promote-skill` が残っている
- 手元: agents 上のダミー or 既存スキル名で dry 確認は任意（破壊的コピーは `-Force` 注意）
