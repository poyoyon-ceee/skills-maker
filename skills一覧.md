# Cursor グローバルスキル一覧

取得日: 2026-06-25（更新）  
対象: このマシン上で Cursor が読み込むグローバルスキル。**運用方針: すべて `~/.cursor/skills/` に集約。プロジェクト内 `.cursor/skills/` は使わない。**

| 種別 | 保存場所 | 件数 |
|------|----------|------|
| 個人（ユーザー作成） | `~/.cursor/skills/` | 19 |
| Cursor 組み込み | `~/.cursor/skills-cursor/` | 18 |

**凡例**

- **コマンド**: `/` で呼び出すときの名前（英語のまま）
- **手動のみ**: エージェントが会話から自動選択しない（`disable-model-invocation: true`）
- **CLI / IDE**: 主にその環境向けのスキル

---

## 個人スキル（`~/.cursor/skills/`）

| コマンド | 説明 | 備考 |
|----------|------|------|
| `/debug-allrun` | デバッガ付き起動で、データ破損・非同期レース・分岐ミスの隠れバグを探索し、自動修正後にバグレポ・修正レポを報告する。 | 手動のみ |

| `/github-make-sync` | 指定した名前で非公開 GitHub リポジトリを作成し、`gh` CLI で現在のプロジェクトに `origin` を設定する。 | 手動のみ |

| `/git-in-clone` | 空の現在ディレクトリに `https://github.com/poyoyon-ceee/skills-maker.git` を `git clone ... .` で取得する。 | 手動のみ |

| `/grill-me` | プランや設計について執拗に質問し、意思決定の分岐を一つずつ潰して共通理解に至る。 | |

| `/webapp-testing` | Cursor のブラウザ MCP や Playwright でローカル Web アプリをテストする。 | |

| `/test-driven-development` | 実装前に RED-GREEN-REFACTOR の TDD を徹底する。Superpowers 本体 + Cursor 向け改良版を採用。 | |

| `/writing-plans` | コーディング前に、ファイルパス・コード断片・検証手順まで含めた実装プランを作る。ローカル Cursor 向け Adapt 版を採用。 | |

### Superpowers（`superpowers/` カテゴリ、12件）

| コマンド | 説明 | 備考 |
|----------|------|------|
| `/brainstorming` | 創造的作業の前に要件と設計を探索。設計書作成後 writing-plans へ。 | Superpowers |
| `/using-git-worktrees` | 設計承認後、隔離 worktree で作業環境を用意。 | Superpowers |
| `/executing-plans` | 書かれたプランをチェックポイント付きでバッチ実行。 | Superpowers |
| `/subagent-driven-development` | タスクごとにサブエージェントを起動、2段階レビューで実装。 | Superpowers |
| `/dispatching-parallel-agents` | 独立タスクを並列サブエージェントで処理。 | Superpowers |
| `/requesting-code-review` | タスク完了・マージ前にコードレビューを依頼。 | Superpowers |
| `/receiving-code-review` | レビュー指摘を技術的に検証して対応。 | Superpowers |
| `/systematic-debugging` | バグ・テスト失敗時に4段階で原因究明。 | Superpowers |
| `/verification-before-completion` | 完了宣言前に検証コマンドで証拠を確認。 | Superpowers |
| `/finishing-a-development-branch` | 実装完了後のマージ/PR/破棄の整理。 | Superpowers |
| `/using-superpowers` | スキルシステムの使い方ブートストラップ。 | Superpowers |
| `/writing-skills` | 新規スキル作成・編集の手順。 | Superpowers |

**除外（ローカル版を維持）:** `test-driven-development`, `writing-plans`

---

## Cursor 組み込みスキル（`~/.cursor/skills-cursor/`）

| コマンド | 説明 | 備考 |
|----------|------|------|
| `/automate` | Cursor Automations（自動化エージェント）を対話的に作成する。 | ローカル環境のみ |

| `/babysit` | PR をマージ可能な状態に保つ。コメント対応・コンフリクト解消・CI 修正をループで行う。 | |

| `/canvas` | チャット横に開ける React ベースの Canvas を使う。分析結果・監査・チャート・表・MCP ツールの出力など、視覚レイアウト向きの成果物に使う。`.canvas.tsx` の作成・編集時も参照する。 | IDE |

| `/create-hook` | Cursor フックを作成する。`hooks.json` やフックスクリプトの追加、エージェントイベント前後の自動処理を設定するときに使う。 | |

| `/create-rule` | Cursor ルールを作成する。コーディング規約・プロジェクト慣習・`.cursor/rules/` や `AGENTS.md` の設定時に使う。 | |

| `/create-skill` | Cursor Agent Skills を新規作成する。`SKILL.md` の書き方や構成について聞かれたときにも使う。 | |

| `/create-subagent` | コードレビュー用・デバッグ用など、用途別のカスタムサブエージェントを作成する。 | 手動のみ |

| `/loop` | このセッション内で、プロンプトやスキルを一定間隔で繰り返し実行する（例: `/loop 5m /foo`）。 | Cloud 無効 |

| `/migrate-to-skills` | 「Applied intelligently」ルール（`.mdc`）やスラッシュコマンド（`.cursor/commands/`）を Agent Skills 形式（`.cursor/skills/`）へ移行する。 | 手動のみ |

| `/review` | Bugbot または Security Review のどちらでレビューするか選び、コード変更をレビューする。 | 手動のみ |

| `/review-bugbot` | Bugbot サブエージェントでコード変更をレビューする。 | |

| `/review-security` | Security Review サブエージェントでコード変更のセキュリティレビューを行う。 | |

| `/sdk` | Cursor SDK（TypeScript `@cursor/sdk` / Python `cursor-sdk`）を使ったアプリ・スクリプト・CI・自動化の構築を案内する。IDE 外からエージェントをプログラム実行するときに使う。 | |

| `/shell` | `/shell` 以降のテキストをそのままシェルコマンドとして実行する。明示的に `/shell` を打ったとき専用。 | 手動のみ |

| `/split-to-prs` | 現在の作業を小さくレビューしやすい複数 PR に分割する。 | |

| `/statusline` | CLI のカスタムステータスラインを設定する。プロンプト上にセッション情報を表示したいときに使う。 | |

| `/update-cli-config` | `~/.cursor/cli-config.json` の CLI 設定を表示・変更する。承認モード・vim モード・サンドボックスなど。 | CLI |

| `/update-cursor-settings` | `settings.json` のエディタ設定を変更する。テーマ・フォント・保存時フォーマット・キーバインドなど。 | IDE |

---

## Superpowers との重複整理（同名スキル）

| スキル | 採用版 |
|--------|--------|
| `test-driven-development` | ローカル改良版（Superpowers 版は**未導入**） |
| `writing-plans` | ローカル Cursor 向け Adapt（Superpowers 版は**未導入**） |

Superpowers 本体は `skills/superpowers/` に **12スキル**として導入済み。上記2つ以外は [obra/superpowers](https://github.com/obra/superpowers) からコピー。

---

## 補足

- **配布パッケージ**は `skills/` 一式。別 PC では `skills/INSTALL.md` → `install.ps1` の1コマンド。
- **設計〜実装の使い分け** — [スキルの使いどころ.md](スキルの使いどころ.md) を参照。
- **`skills-cursor/`** は Cursor が管理する組み込みスキル。手動編集は非推奨。
