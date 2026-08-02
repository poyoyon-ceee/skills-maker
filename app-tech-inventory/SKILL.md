---
name: app-tech-inventory
description: Scan a codebase's dependency manifest files (package.json, Cargo.toml, requirements.txt, pyproject.toml, go.mod, etc.) and extract its technology stack (frameworks, major libraries, versions) into a fixed frontmatter format for an Obsidian app ledger note. Use this whenever the user asks to inventory, catalog, or identify what framework/library/tech stack an app or repo uses — especially when they say they don't remember or aren't sure what an app was built with. Also use as step ①-a of the "アプリ台帳" (app ledger) workflow, before technology-update-notice matching (step ③) can run.
---

# App Tech Inventory (アプリ台帳 棚卸し)

このスキルは、ナレッジ集約システムの「アプリ台帳」プロジェクトの①-a工程（棚卸し）を実行する。
本人（ユーザー）が各アプリの使用技術を正確に把握していない前提で、依存関係ファイルから機械的に技術スタックを抽出する。

参照元: `spec_20260802_アプリ台帳.md`（Obsidian Vault内、ナレッジ集約システム仕様書フォルダ）

## いつ使うか

- 「このアプリ何のフレームワーク使ったっけ」のように、ユーザーが技術スタックを把握していない状態でアプリの棚卸しを依頼したとき
- 複数アプリ・複数リポジトリをまとめて棚卸しする「アプリ台帳」バッチ作業のとき
- 既存の台帳ノートを最新の依存関係で更新し直すとき

## 手順

### 1. 対象リポジトリを確認する

ユーザーから対象ディレクトリ（複数可）を確認する。指定がなければ、既知のプロジェクトルート配下を探索してよいか確認してから進める。

### 2. 依存関係ファイルを探す

各リポジトリのルート（および主要サブディレクトリ）で以下を探す。見つかったものだけを使う。全部揃っている必要はない。

| ファイル | 抽出対象 | 備考 |
|---------|---------|------|
| `package.json` | JS/TS系: React, Vue, Tauri (via `src-tauri/Cargo.toml`との併用が多い), Electron等 | `dependencies` と `devDependencies` 両方見る |
| `Cargo.toml` | Rust系: Tauri本体, その他crate | `[dependencies]` セクション |
| `requirements.txt` / `pyproject.toml` | Python系: フレームワーク・主要ライブラリ | pyproject.tomlは`[project.dependencies]`や`[tool.poetry.dependencies]` |
| `go.mod` | Go系 | — |
| `Gemfile` | Ruby系 | — |

Tauriアプリは`package.json`（フロント側）と`src-tauri/Cargo.toml`（Rust側）の両方を見ること。どちらか片方だけだと技術スタックが不完全になる。

### 3. バージョンを記録する

各主要依存について、固定バージョンかレンジ指定か（`^1.2.3` 等）をそのまま記録する。正規化・推測はしない。ファイルに書かれた値をそのまま転記する。

### 4. 「主要」技術だけ抽出する

全依存関係を機械的に列挙すると台帳がノイズだらけになる。以下を優先的に拾う:

- アプリの骨格を決めるフレームワーク（Tauri, React, Next.js, FastAPI, Flask等）
- ビルド・ランタイムの土台になるもの
- 将来のアップデート通知（③工程）で追跡する価値があるもの

以下は基本的に省く:
- リンター・フォーマッター等の開発補助ツール
- 極小のユーティリティライブラリ（lodash単体の使用等、判断に迷ったらユーザーに聞く)

### 5. 出力フォーマット（Obsidianノート frontmatter）

抽出結果は、以下の固定フォーマットで1アプリ1ブロックとして出力する。既存の台帳ノートがあれば追記・更新し、なければ新規ノートの草稿として提示する。

```yaml
種別: アプリ台帳
アプリ名: {リポジトリ名 or アプリ名}
技術スタック:
  - name: Tauri
    version: "^2.0.0"
    role: デスクトップアプリフレームワーク
  - name: React
    version: "^18.2.0"
    role: UI
最終更新確認日: {YYYY-MM-DD}
```

- `種別`と`最終更新確認日`は本書（現状まとめ）第8.3章の予約共通キー設計と整合させるため、キー名は変更しない
- `技術スタック`配列の各要素に`role`（このアプリでの役割・一言）を必ず添える。バージョン番号だけでは後で見返したときに意味が分からないため

### 6. 実行後にユーザーへ提示する

- 抽出できたもの／できなかったもの（依存関係ファイルが見つからない、パースできない等）を分けて報告する
- 「主要」判定で省いたものがあれば、何を省いたか一言添える(ユーザーが後で「あれも欲しかった」とならないため)
- 台帳ノートへの保存は、ユーザーに保存先フォルダを確認してから行う(spec未決事項: 保存先フォルダ未確定のため)

## 注意点

- ユーザーは技術構造を把握していない前提。専門用語で問い詰めず、抽出結果は素直に一覧で見せる
- 推測でバージョンを埋めない。ファイルに書かれていない情報は「不明」として残す
- このスキルは棚卸し（①-a）のみを担当する。commit履歴分析（②）やリリースノート突き合わせ（③）は別工程であり、このスキルの範囲外
