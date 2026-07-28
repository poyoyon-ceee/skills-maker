# MASTER_PROTOCOL_SOURCE（掟のカタログ）

本ドキュメントは、プロジェクトの「憲法」となる規範の原典である。AIエージェントはヒアリング結果に応じて**必要な節のみを抽出・調整**し、ターゲットの **`.project_rules/MASTER_PROTOCOL.md`** を生成せよ。

**明示的除外**: リポジトリ整理・ログ退避などのクリーンアップ自動フローは、エディタの **`/command` 側に装備済み**とみなす。**本カタログから「合言葉」「大掃除マクロ」の節は生成しないこと。**

---

### [TEMPLATE: MASTER_PROTOCOL.md 本文]

インタビューで決まった値は `{{...}}` を置換し、適用しない節は削除してよい。枝番・見出しは生成時に重複しないよう整理すること。

````markdown
# プロジェクト掟（MASTER_PROTOCOL）

> **優先順位**: グローバル CLAUDE.md（`~/.claude/CLAUDE.md`） > **本ファイル** > `PROJECT.md`
> グローバル CLAUDE.md と矛盾する場合はグローバル CLAUDE.md に従う。本ファイルは **このプロジェクト固有の差分とリマインダー**。

> **関連ドキュメント**: 技術品質・ナレッジは `.project_rules/KNOWLEDGE_BASE.md` および `docs/` を参照。

## 0. グローバル掟（グローバル CLAUDE.md に委譲）

以下は **グローバル CLAUDE.md（Tom ルール）** に従う。ここでは再掲しない。

- ユーザー向け出力は日本語
- 指示スコープ外の変更・リファクタ・コメント/Print 削除禁止
- 無断コミット禁止、Git 安全（force push / 履歴改変 / 長命ブランチ禁止 等）
- 合意形成中はコード変更しない（**トリガー語は `PROJECT.md`**）

> **退避ファイルの参照禁止**（本プロジェクト）:
> - `archive`、`backup`、`old` 等の退避物や zip は現行仕様と整合しない可能性がある。
> - **ユーザーの明示指示がない限り、解凍・内部参照を禁止する。**

---

## 1. 基本方針（プロジェクト）

- **ドキュメント同期**: `implementation_plan.md`、`walkthrough.md`、`task.md` 等を運用する場合は常に最新にし、日本語で保つ。

## 2. Git 運用（このプロジェクトで確定）

**`PROJECT.md` の Git 作業ブランチと一致させること。**

- **パターン A — `main` 一本**: 開発の中心ブランチ **`{{GIT_MAIN_BRANCH}}`**（通常 `main`）
- **パターン B — 安定 `main` + 開発 `develop`**: **`{{GIT_STABLE_BRANCH}}`**（通常 `main`）は安定用。日常の commit/push は **`{{GIT_DEVELOP_BRANCH}}`**（通常 `develop`）。**AI が独断で `main` にマージしない。**

**作業ブランチ `{{GIT_WORK_BRANCH}}`**: Git 操作（checkout、一時ブランチ、マージ試行等）の末尾で **必ず HEAD をここに戻す**。パターン B では `develop` 固定。

### 入店・退店
- **入店**: 新タスク開始前に「GitHub から最新をプルしたか」をリマインドする。
- **作業中断時**: ユーザーが Git で変更を破棄した場合、エディタの現状態を読み直し、過去提案に固執しない。
- **退店**: タスク完了後、「コミットしてプッシュしましょう」と促す（**ユーザーが禁止していれば従う**）。

### コミットメッセージ
- 「`.`」「`1`」「`修正`」等の短文コミットを**完全に許容**する。AI は細部説明を強要しない。

### コンフリクト
- プル／プッシュで競合したら、勝手に解決せず問題ファイルを示し、ユーザーの指示を待つ。

## 3. 実装フェーズ（このプロジェクト）

- **トリガー語**: `PROJECT.md` の「実装開始トリガー」に従う。明示指示までコード変更しない（詳細はグローバル CLAUDE.md）。
- **ノンストップ**: 実装開始後は、Yes/No 等の途中確認で止めず、指示タスク完了まで自動で進める（ブロッカー・仕様不明時は別）。

## 4. バージョンタグ（devVERSION）

- **形式**: `dev{VERSION}.YYYYMMDD.N` （例: `dev2.6.0.20260318.1`）
- **確認先**: `package.json`、`Cargo.toml`、`*.csproj` 等から最新 `{VERSION}` を取得する。
- **用途**: ウィンドウタイトル、キャッシュバスター、`deploy.js` 前後の確認など。**デプロイやリリース手順でインクリメントを忘れないこと。**

## 5. プロジェクト固有（インタビュー結果／単一の真実）

以下は **`PROJECT.md` の同名項目と語句を一致させること。** この節のみユーザーヒアリングで埋める。

- **接続形態**: {{CONNECTIVITY}}
- **配布・実行形態**: {{DISTRIBUTION}}
- **標準タイムゾーン**: {{TIMEZONE}}（通常 `Asia/Tokyo` / JST）

補足制約（必要なときだけ記載・不要なら削除）:

{{PROJECT_EXTRA_CONSTRAINTS}}

---

## 6. アーカイブとレビュー

- `docs/archives.zip` は **Git で追跡しない**運用でもよい。**必要に応じ**生成・更新し、運用ルールを `PROJECT.md` または `docs/TROUBLESHOOTING.md` に一行残す。
- `docs/AI_REVIEW_PROMPT.md` でセルフレビューし、結果は `docs/REVIEW_PROGRESS.md` に記録する。

````

---

## 🏗️ 【STRUCTURE】配置の絶対ルール（Tauri + Vite 標準）

新規構築でフロントを Vite + 素の JS とする場合、次を**既定**とする（他スタックならヒアリングで差し替え）。

1. **フロントのルート**: `ui/`（`ui/index.html`、Vite `root: 'ui'`）
2. **核心ロジック**: `ui/src/core/`（EventBus、StateManager 等）
3. **ユーティリティ**: `ui/src/utils/`（Sanitizer、Config、Migration、Diff 等）
4. **ビルド出力**: `dist/`（レポジトリルート、`tauri.conf.json` の `frontendDist` と一致）
5. **Tauri Rust**: `src-tauri/`
6. **AI 誘導**: ルート `PROJECT.md`、`docs/`（`TROUBLESHOOTING.md`、`AI_REVIEW_PROMPT.md` ほかヒアリングで必要なもの）
7. **掟**: `.project_rules/MASTER_PROTOCOL.md`、`KNOWLEDGE_BASE.md`（任意）

---

## 🛡️ 【GUARDRAILS】安全とセキュリティ（常に適用しやすい短則）

- Tauri でローカルデータやバンドル UI を読むなら、`tauri.conf.json` の `app.security.assetProtocol.scope` に **`./data/*`** と **`./ui/*`**（または実際の公開パス）を含める。
- **接続形態がオフライン**のときは、`PROJECT.md`・`MASTER_PROTOCOL`・`index.html` の外部 CDN 記述が**すべて**オフライン方針と矛盾しないようにすること（オンライン専用の `<link>` は生成しない）。
- **`PROJECT.md` と掟の「固有情報」は二重記述しない。** テーブルでも箇条書きでもよいが、**文言と意味が一章に集約**されていること。

---

## 📌 【META】GENERATION_RULES（AI がカタログを読むときの約束）

- **YAGNI**: ユーザーが選ばなかったファイル・モジュールは作らない。
- **トリガー語**: 「実装して」等は `PROJECT.md` にのみ書き、憲法はプロジェクト差分に留める。
- **重複禁止**: グローバル CLAUDE.md と同内容の条文を `MASTER_PROTOCOL.md` に再掲しない（委譲節で十分）。
- **Git**: 初回インタビューでパターン A / B と `{{GIT_WORK_BRANCH}}` を確定させる。パターン B のとき、AI の Git 操作後は**必ず `develop`（`{{GIT_WORK_BRANCH}}`）へ戻す**ことを生成する `MASTER_PROTOCOL.md` に含める。グローバル CLAUDE.md の独断ブランチ禁止と矛盾させない。
