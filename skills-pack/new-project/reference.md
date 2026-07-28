# New Project Skill — Reference

## 同梱ファイル（scripts/）

| ファイル | 役割 |
|---|---|
| `scaffold.js` | ヒアリング UI + 生成フロー |
| `lib/parser.js` | Markdown テンプレート抽出 |
| `lib/writer.js` | プレースホルダ置換 + 書き出し |
| `FILE_TEMPLATE_SOURCE.md` | コード・設定テンプレ原典 |
| `MASTER_PROTOCOL_SOURCE.md` | 憲法テンプレ原典 |
| `package.json` | `@clack/prompts`, `picocolors` |

## 原典リポジトリとの同期

開発・更新の正本: `original-source-maker` リポジトリ（`c:\Dev-App\original-source-maker` 等）。

スキルへ反映するときは以下を `scripts/` にコピー:

- `scaffold.js`
- `lib/parser.js`, `lib/writer.js`
- `FILE_TEMPLATE_SOURCE.md`
- `MASTER_PROTOCOL_SOURCE.md`

コピー後: `cd scripts && npm install`

## 憲法テンプレの方針（グローバル CLAUDE.md との重複）

生成される `.project_rules/MASTER_PROTOCOL.md` は:

- **グローバル CLAUDE.md と被る条文**（日本語、Git 安全、無断変更等）→ 委譲節のみ。再掲しない
- **プロジェクト固有**（Git A/B、devVERSION、接続形態、入店退店等）→ フル記載
- **優先順位**: グローバル CLAUDE.md（`~/.claude/CLAUDE.md`） > MASTER_PROTOCOL > PROJECT.md

## ヒアリング項目（CLI）

1. プロジェクト名・説明・作成者
2. 配信形式: Web / Tauri / MAUI
3. 接続形態: Offline / Online / Hybrid
4. テンプレレベル: Minimal / Standard / Full
5. モジュール（MAUI 除く）: EventBus, StateManager, 等
6. Git: パターン A (main) / B (main + develop)

## 推奨フロー（新規）

```
brainstorming（任意）→ grill-me（任意）→ new-project スキル → npm install → 実装
```

## トラブルシュート

| 問題 | 対処 |
|---|---|
| `Cannot find module '@clack/prompts'` | `scripts/` で `npm install` |
| テンプレが見つからない | `scaffold.js` と同じ `scripts/` に `.md` 原典があるか確認 |
| 上書きしたくない | 空ディレクトリで実行。競合ファイルがあれば中止 |
