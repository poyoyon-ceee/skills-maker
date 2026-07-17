---
name: new-project
description: >-
  Scaffold a new greenfield project using the Hidem project kit (Web/Tauri/MAUI)
  via bundled CLI. Use ONLY once at project start when the user wants to create
  a new app, new project, scaffold, or says 新規プロジェクト / プロジェクト立ち上げ /
  アプリを作りたい. Do NOT use for existing projects, feature work, or bug fixes.
disable-model-invocation: true
---

# New Project（プロジェクト立ち上げ）

新規プロジェクトの **Day 0 に1回だけ** 使う。既存リポジトリへの機能追加では使わない。

## 前提

- ユーザーは **新規グリーンフィールド** を作りたい
- 設計が未整理なら、先に brainstorming / grill-me を提案してよい
- 生成物は **カレントディレクトリ**（`process.cwd()`）に書き出される

## スクリプトの場所

| OS | パス |
|---|---|
| Windows | `%USERPROFILE%\.claude\skills\new-project\scripts\scaffold.js` |
| macOS/Linux | `~/.claude/skills/new-project/scripts/scaffold.js` |

依存は `scripts/` 配下に同梱。初回のみ `scripts/` で `npm install` が必要（未実施なら先に実行）。

## ワークフロー

### フェーズ 0: 安全確認

1. **場所**: プロジェクトを作る **空（または意図した）ディレクトリ** にいるか確認
2. **競合**: 次が既にある場合は上書きせずユーザーに確認
   - `PROJECT.md`, `package.json`, `.project_rules/MASTER_PROTOCOL.md`
3. **依存**: `scripts/node_modules` が無ければ `npm install` を `scripts/` で実行

### フェーズ 1: Scaffolder 実行

ターミナルで対話 CLI を起動する。**ユーザーがターミナルで回答する。**

Windows (PowerShell):

```powershell
node "$env:USERPROFILE\.claude\skills\new-project\scripts\scaffold.js"
```

macOS / Linux:

```bash
node ~/.claude/skills/new-project/scripts/scaffold.js
```

- 実行中は AI がヒアリング選択肢を補助してよい
- **AI は自分でプロジェクトファイルを生成しない**（必ず CLI 経由）

### フェーズ 2: 事後フォロー

Scaffolder 完了後:

1. `npm install`（`package.json` がある場合）
2. `PROJECT.md` と `.project_rules/MASTER_PROTOCOL.md` を読んでから実装フェーズへ
3. Git 初期化・初回コミットは **ユーザーが依頼したときのみ**
4. **このスキルは以降使わない**（同一プロジェクトで再実行しない）

## 生成される主なもの

- `PROJECT.md`, `.project_rules/MASTER_PROTOCOL.md`
- Web/Tauri: `package.json`, `ui/`, `vite.config.js`, `deploy.js`, 任意で `src-tauri/`
- 選択モジュール: `ui/src/core/`, `ui/src/utils/`
- Standard 以上: `docs/AI_REVIEW_PROMPT.md` 等

## 禁止事項

- 既存プロジェクトで `scaffold.js` を再実行しない
- CLI を使わず AI がテンプレから直接大量ファイルを Write しない
- 新規立ち上げ以外のタイミングで本スキルを適用しない

## 詳細

テンプレ原典・保守手順は [reference.md](reference.md) を参照。
