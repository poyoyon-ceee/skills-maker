# グローバルスキル一覧（日常パック ＋ マーケオプトイン47件・未インストール）

取得日: 2026-08-17  
**パック正本の件数:** `skills-pack/MANIFEST.json`（`scripts/generate-manifest.ps1`）。手で件数を固定しない。  
**いま入っているもの（この PC）:** グローバル同期は未実施なら、前回 install 時点のまま。マーケはリポジトリにパックがあるだけで **グローバル未導入**。

**運用方針**

| 項目 | 内容 |
|------|------|
| 日常（共通） | `skills-pack/` → `install.ps1` で `~/.agents/skills/` に**平置き**。Cursor / Codex / ChatGPT 系が共通で読む正本。件数は MANIFEST |
| 日常（Cursor 固有） | `chat-handoff` / `skill-creator` / `promote-skill` の3件だけ `~/.cursor/skills/`（`install.ps1`）。`promote-skill` は手順として Claude でも使う（`~/.claude` にも入り、Gate 1 で `~/.claude` 可） |
| Claude Code | 同パックを `install-claude.ps1` で `~/.claude/skills/` に平置き（除外9あり → 48件）。`~/.agents` は書かない |
| マーケ | `skills-pack-marketing/` は**作るが入れない**。必要になったときだけ `install.ps1`（Cursor のみ）。通常更新では入らない・戻らない |
| プロジェクト内 | `.cursor/skills/` は使わない |
| 重複の禁止 | **Cursor 向け: 同名を `~/.agents` と `~/.cursor` の両方に置かない。** `~/.agents`∩`~/.claude` は可 |

**Include Third-Party トグルの誤解（重要）**

Settings → Rules, Skills, Subagents → **Include Third-Party Plugins, Skills, and Other Configs** を OFF にしても **`~/.agents/skills` は読まれ続ける**。あのトグルの対象は `~/.claude/skills`・`CLAUDE.md`・Copilot 設定など「よそのベンダー固有の設定」で、`~/.agents/` は `AGENTS.md` と同じベンダー中立の共通標準としてネイティブに扱われるため。`~/.agents` 由来の重複はフォルダ整理でしか直らない（[skills重複処理.md](skills-pack/skills重複処理.md)）。

**凡例**

- **コマンド**: `/` で呼び出すときの名前
- **手動のみ**: `disable-model-invocation: true`。会話から自動選択されず、明示的に呼ぶ必要がある
- **使いどころ**: どんな場面・キーワードで出すべきか
- **各カテゴリ内の並び**: コマンド名のアルファベット順

日常の生データ: [skills-pack/MANIFEST.json](skills-pack/MANIFEST.json)  
マーケのカタログ: [marketing-skills一覧.md](marketing-skills一覧.md) / [skills-pack-marketing/MANIFEST.json](skills-pack-marketing/MANIFEST.json)

---

## 目次

1. [オーケストレーター（playbooks・7件）](#1-オーケストレーターplaybooks7件)
2. [ドキュメント／データ処理（10件）](#2-ドキュメントデータ処理10件)
3. [Google Workspace 連携（3件）](#3-google-workspace-連携3件)
4. [設計・開発ワークフロー（Superpowers 系・12件）](#4-設計開発ワークフローsuperpowers系12件)
5. [独自の開発系スキル（12件）](#5-独自の開発系スキル12件)
6. [デザイン・コンテンツ制作（6件）](#6-デザインコンテンツ制作6件)
7. [ナレッジ管理・リサーチ（5件）](#7-ナレッジ管理リサーチ5件)
8. [GitHub / Git 運用（3件）](#8-github--git-運用3件)
9. [マーケティング（オプトイン・47件・未インストール）](#9-マーケティングオプトイン47件未インストール)

---

## 1. オーケストレーター（playbooks・7件）

**手動のみ。日常パックに含まれるのはルーター1＋台本6。** 中身のスキル自体は自動で連鎖しない。

**入口:** どれを使うか分からなければ `/route-playbook`。要求に合う台本＋適応スケッチを提案し、`GO` 後に該当 playbook へ渡す。  
**各 playbook:** 起動直後に **Adaptive proposal gate**（必須/任意/スキップ・通し/チェックポイント）を出し、承認まで作業しない。スキップした Step は Done when から外す。

| コマンド | 内容 | 使いどころ |
|----------|------|-----------|
| `/playbook-app-improvement` | `systematic-debugging` → `improve-codebase-architecture` → `requesting-code-review` → `react-best-practices`（非 React はスキップ可）。 | 再発バグ、複雑化した既存アプリ |
| `/playbook-article-production` | `content-research-writer` → `doc-coauthoring` → `edit-article` →（任意・**marketing パック導入時のみ**訴求調整）。 | X投稿・note記事・メルマガ・セミナー告知文 |
| `/playbook-document-data` | `pdf`/`docx`/`xlsx` 取込・構造化（Phase 1）→ 任意で `gws`（Phase 2）。**Firecrawl は明示指示がない限り使わない。** | 見積・請求・契約の整理、Excel/Word 比較表、Drive 資料 |
| `/playbook-fable5-7day` | `skill-creator` → `brainstorming` → `grill-me` → `verification-before-completion` → `systematic-debugging`。業務棚卸しからスキル作成・設計・穴埋め・QA・デバッグ。 | 自分の業務 OS を作り直したい／スキル基盤を整えたい |
| `/playbook-mini-webapp` | `to-prd` → `frontend-design` → `web-artifacts-builder` → `webapp-testing` → `verification-before-completion`。 | 社内管理表・フォーム・簡易ダッシュボード |
| `/playbook-research-assets` | `notebooklm` → `obsidian-vault`（＋任意で markdown / canvas）→ `content-research-writer`。 | 散在ナレッジの資産化 |
| `/route-playbook` | 要求を見て最適な `/playbook-*` を1つ（＋代替）提案し、適応スケッチを出して `GO` 待ち。実行はしない。マーケ未導入なら `playbook-lp-creative` は候補から外すか導入を促す。 | 「どのplaybook？」「台本を選んで」「記事書いて／見積まとめて」など入口が曖昧なとき |

`/playbook-lp-creative` は日常パック外・**未インストール** → [§9](#9-マーケティングオプトイン47件未インストール)。パック導入後は Adaptive proposal gate 付き。`/route-playbook` からも誘導可。

## 2. ドキュメント／データ処理（10件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/doc-coauthoring` | 文書・提案書・技術仕様・意思決定文書を「文脈収集→推敲・構造化→読者テスト」の3段階で共同執筆。 | 「ドキュメントを書きたい」「提案書を作りたい」「PRDを書きたい」など、ある程度分量のある文章作成 |
| `/doc-maint` | 既存リポジトリの README / docs を読み取り専用監査し、維持・統合・修正・移動・要確認の5分類で提案。承認後に文書だけ適用。コードは触らない。`project-foundation` が既存と判定したときの受け先。 | 「READMEを直して」「docsを整理して」「ドキュメントが古い」「重複を消して」「オンボーディングを分かりやすく」 |
| `/docx` | Word 文書（.docx）の作成・読取・編集。目次・見出し・ページ番号・レターヘッド付き文書、画像挿入・置換、検索置換、変更履歴・コメント対応。 | 「Wordドキュメント」「.docx」「レポート」「メモ」「レター」「テンプレート」の作成・編集依頼 |
| `/improve-codebase-architecture`（手動のみ） | コードベースをスキャンして「深化の余地」をHTMLレポートで可視化し、選んだ項目についてgrill-me形式で深掘り。 | 過去のコードの複雑化を解消したい、リファクタリング候補を洗い出したい |
| `/pdf` | PDF のテキスト・表抽出、結合・分割、回転、透かし、新規作成、フォーム入力、暗号化/復号、画像抽出、スキャンPDFのOCR。 | 「.pdf」に言及、または PDF を作りたい／読みたい／編集したいとき |
| `/pptx` | .pptx が入出力どちらかに関わる全作業。スライド作成、テキスト抽出、既存プレゼン編集、テンプレート/レイアウト/スピーカーノート操作。 | 「デッキ」「スライド」「プレゼン」「.pptx」に言及されたら常に使う |
| `/promote-skill` | スキル作成直後の2段確認: global に入れる？→ skills-pack に同期する？。宛先は `~/.agents` / `~/.cursor` / `~/.claude`。Cursor・Claude Code 両対応。パス未検出時は聞いて、検証前は書かない。 | create-skill / skill-creator 完了後、「globalに入れる」「skills-packに同期」 |
| `/skill-creator` | 新規スキル作成、既存スキルの編集・最適化、評価(eval)実行、性能ベンチマーク。 | スキルを新規作成したい／SKILL.mdの書き方を聞かれたとき |
| `/theme-factory` | スライド・文書・レポート・LP等に一貫したテーマ（色・フォント）を適用。10種のプリセットテーマ or 新規生成。 | 成果物のトンマナを統一したいとき。marketing パックの `playbook-lp-creative` でも使用 |
| `/xlsx` | 既存/新規の .xlsx・.xlsm・.csv・.tsv の読取・編集・修正（列追加、数式計算、書式設定、グラフ化、汚いデータの整形）。成果物は必ずスプレッドシート。 | 「このExcelを直して」「スプレッドシートを作って」など、成果物がスプレッドシートである依頼 |

---

## 3. Google Workspace 連携（3件）

**前提: `gws` CLI (`@googleworkspace/cli`) のインストールと OAuth 認証（`gws auth login`）が別途必要。PCごとの設定。**

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/gws-docs` | Google Docs の読み書き（`gws docs` コマンドのラッパー）。 | Google ドキュメントの内容を読む・編集する依頼 |
| `/gws-drive` | Google Drive のファイル・フォルダ・共有ドライブ管理（`gws drive` コマンドのラッパー）。 | Drive 上のファイル検索・一覧・整理の依頼 |
| `/gws-sheets` | Google Sheets の読み書き（`gws sheets` コマンドのラッパー）。 | Google スプレッドシートの内容を読む・編集する依頼 |

---

## 4. 設計・開発ワークフロー（Superpowers系・12件）

[obra/superpowers](https://github.com/obra/superpowers) から導入。**`test-driven-development` と `writing-plans` はローカル改良版を採用しており、Superpowers版は導入していない**（重複防止）。

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/brainstorming` | 創造的作業（機能追加・コンポーネント作成・挙動変更）の**前に必ず**要件と設計を対話的に探索。承認なしに実装させない強いゲート。 | 何か新しく作る・変更する前段階。「これは簡単すぎて設計不要」という思い込みへの対抗策 |
| `/dispatching-parallel-agents` | 2つ以上の独立したタスク（別ファイル・別バグ等）を並列サブエージェントで同時処理。 | 複数の無関係な失敗やタスクを同時に片付けたいとき |
| `/executing-plans` | 書かれた実装プランを読み込み、批判的にレビューしてからチェックポイント付きでタスクを実行。 | すでにプランファイルがあり、別セッションで実行したいとき |
| `/finishing-a-development-branch` | 実装完了・テスト通過後、マージ/PR/破棄などの選択肢を整理して提示し、選んだワークフローを実行。 | 開発ブランチの後始末をどうするか決めるとき |
| `/receiving-code-review` | レビュー指摘を鵜呑みにせず、技術的に検証してから対応。読む→理解→検証→評価→応答→実装の順で処理。 | コードレビューのフィードバックを受け取ったとき |
| `/requesting-code-review` | 完了したタスク・大きな機能実装後・マージ前に、専用コンテキストを持つレビュアーサブエージェントへレビュー依頼。 | タスク完了時、マージ前、行き詰まったときの新しい視点 |
| `/subagent-driven-development` | タスクごとに新規サブエージェントを起動し、実装後に毎回レビュー、最後に全体レビュー。 | 独立したタスクが並ぶ実装プランを、今のセッション内で高品質に進めたいとき |
| `/systematic-debugging` | バグ・テスト失敗・想定外挙動に遭遇したら、**必ず根本原因調査を先に完了してから**修正提案する4段階プロセス。 | あらゆるバグ調査の前段階。「とりあえず直す」を禁止 |
| `/using-git-worktrees` | 既存の隔離状態を検知した上で、feature作業やプラン実行前に隔離ワークスペース（git worktree等）を用意。 | 設計承認後、本体を汚さず並行作業したいとき |
| `/using-superpowers` | スキルシステムの使い方ブートストラップ。「1%でも関連しそうならスキルを必ず使う」という原則を強制。 | セッション開始時（自動判定用の基盤スキル） |
| `/verification-before-completion` | 「完了した」「直った」と主張する前に、検証コマンドを実際に実行し出力で裏付ける。証拠なき完了宣言を禁止。 | 完了報告・コミット・PR作成の直前 |
| `/writing-skills` | 新規スキルの作成・編集・デプロイ前の検証。TDD（RED-GREEN-REFACTOR）をドキュメント作成に応用。 | 新しいスキルを書く、既存スキルを直す、公開前の動作確認 |

---

## 5. 独自の開発系スキル（12件）

文書まわりの入口は `/project-foundation`（自動）。判定中は書き込まない。

- `new` → `/new-project`（手動・空ディレクトリの scaffold）
- `existing` → `/doc-maint`（[§2](#2-ドキュメントデータ処理10件)。監査→承認→文書のみ）
- `ambiguous` → 停止して確認

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/chat-handoff`（手動のみ） | 別PCで続きをやるための引き継ぎメモを、リポジトリ直下の `質疑応答M-D.MD` に作成・追記。結論・決定・未解決TODOを残す。Cursor チャット履歴は端末に残る前提。 | 「別PC用に残して」「引き継ぎ書いて」「質疑応答に落として」「続きは別端末で」と明示されたとき。通常の備忘録は `/session-recap` |
| `/git-guardrails` | 危険なGitコマンド（push、reset --hard、clean、branch -D等）を実行前にブロックするフックを設定。 | 誤操作防止のガードレールを設定したいとき |
| `/new-project`（手動のみ） | 空ディレクトリ向け scaffold。CLI 対話。必須は README。Hidem プロファイルは選択式。既存ファイルは上書きしない。 | `project-foundation` が新規と判定したとき。既存リポジトリでは使わない |
| `/project-foundation` | 新規/既存/判定不能を振り分ける文書標準の入口。判定中は書き込まない。new → `new-project`、existing → `doc-maint`。 | 「新規プロジェクト」「scaffold」「READMEを直して」「docsを整理して」 |
| `/react-best-practices` | Vercel Engineering によるReact/Next.jsパフォーマンス最適化ガイド（8カテゴリ70ルール）。 | React/Next.jsのコンポーネント作成・データフェッチ実装・パフォーマンスレビュー・リファクタリング |
| `/session-recap`（手動のみ） | 今の会話を `備忘録.md` の日付エントリにする（決定・調査・次のTODO）。コード変更履歴用の `変更履歴.md` には書かない。 | 「まとめて」「備忘録に残して」「このやり取りを記録して」と明示されたときだけ |
| `/test-driven-development` | RED-GREEN-REFACTORのTDDを実装前に徹底。ローカル改良版（Superpowers本体＋マルチスタックテストコマンド表付き）。 | 機能追加・バグ修正・リファクタリング前。「TDDで」「テストファーストで」と言われたとき |
| `/to-issues`（手動のみ） | プラン・仕様・PRDを、独立して着手可能な「トレーサーバレット」の垂直スライスIssueに分解。 | PRDや設計書を実装可能な単位のIssueに分割したいとき |
| `/to-prd`（手動のみ） | 今の会話をヒアリングなしでそのままPRDに合成し、Issueトラッカーへ公開。 | すでに会話で要件が固まっており、そのままPRD化したいとき |
| `/web-artifacts-builder` | React 18 + TypeScript + Vite + Tailwind + shadcn/ui で、状態管理やルーティングを含む多コンポーネントのHTMLアーティファクトを構築。 | 単純な単一ファイルHTML/JSXでは足りない、複雑なWebアーティファクトを作りたいとき |
| `/webapp-testing` | Cursorのブラウザ MCP または Playwright スクリプトでローカル Web アプリをテスト。ユニット/E2E(IDE)/E2E(スクリプト)の使い分け表あり。 | 「アプリをテストして」「UIを確認して」、フロントエンドの動作検証全般 |
| `/writing-plans` | ファイルパス・コード断片・検証手順まで含めた実装プランを、コーディング前に作成。ローカル Cursor 向け Adapt 版。 | 仕様が複数ステップにわたる非自明な機能に着手する前 |

---

## 6. デザイン・コンテンツ制作（6件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/canvas-design` | .png/.pdfで独自のビジュアルアート（ポスター・作品・デザイン）を、デザイン哲学の作成→視覚表現の2段階で制作。 | ポスター、アート作品、静的なビジュアルデザインを作りたいとき |
| `/content-research-writer` | リサーチ・引用付与・フック改善・アウトライン反復・セクションごとのリアルタイムFBで、執筆をパートナー作業に変える。 | ブログ・記事・ニュースレター・技術文書の執筆、根拠付きの文章を書きたいとき |
| `/debug-allrun`（手動のみ） | デバッガ付きで起動し、サイレントなデータ破損・非同期レース・分岐ミスという3種の隠れバグを能動的に探索・自動修正・報告。 | `/debug-allrun` 明示呼び出し時。「クラッシュしないから安全」を信用しない徹底デバッグ |
| `/edit-article`（手動のみ） | 記事を見出しで章分けし、各章を明確さ・一貫性・流れの観点で書き直す（1段落最大240字）。 | 記事の下書きを編集・改善・推敲したいとき |
| `/frontend-design` | テンプレート感のない、意図を持った視覚デザインの方向性（配色・タイポグラフィ・レイアウト）を設計思想ガイド。 | 新規UI構築、既存UIの作り直し、「他と被らないデザインにしたい」とき |
| `/grill-me` | プラン・設計について執拗に一問一答で質問し、決定木の分岐を一つずつ潰して共通理解に至る。各質問に推奨回答も提示。 | 「grill me」「プランを詰めて」と言われたとき、設計の穴を潰したいとき |

---

## 7. ナレッジ管理・リサーチ（5件）

Obsidian 系は **3スキル連携**。`obsidian-vault` が vault パス（`D:\vault`）と運用、`obsidian-markdown` が文法、`json-canvas` が `.canvas` 俯瞰。`app-tech-inventory` はアプリ台帳の①-a/①-b＋軽量②（人間向け名刺本文と直近ダイジェスト）。③は別工程。

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/app-tech-inventory` | 依存関係ファイルから技術スタックを YAML に残し、本文に何のアプリか・できること・直近の変化（タグ間、無ければ90日、最大7行）を書く。未反映は全件保存後にまとめて `doc-maint`（README限定）を提案。 | 「このアプリ何のフレームワーク使ったっけ」「何のアプリ？何ができる？」、アプリ台帳の棚卸し、複数リポジトリの一括確認 |
| `/json-canvas` | `.canvas` ファイル（ノード・エッジ・グループ）の生成・編集。`D:\vault\canvas\` 推奨。kepano/obsidian-skills 由来。 | マインドマップ、フローチャート、Index の視覚俯瞰を Canvas で作りたいとき |
| `/notebooklm` | Google NotebookLM のノートブックにブラウザ自動化で問い合わせ、Geminiの根拠付き回答を取得。ハルシネーションを大幅抑制。 | NotebookLMのURLを共有された、「自分のNotebookLMに聞いて」と言われたとき |
| `/obsidian-markdown` | callout、frontmatter（properties）、embed、wikilink 等の Obsidian Flavored Markdown 文法。kepano/obsidian-skills 由来。 | Obsidian ノートの書式・callout・メタデータを正確に書きたいとき |
| `/obsidian-vault` | `D:\vault` 内のノートを wikilink・インデックスノートで検索・作成・整理。vault パスと命名規則の正本。 | Obsidianでノートを探す・作る・整理したいとき |

---

## 8. GitHub / Git 運用（3件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/git-guardrails` | （[§5](#5-独自の開発系スキル12件) 参照）危険なGit操作をブロック | — |
| `/git-in-clone`（手動のみ） | 指定したGitHubリポジトリを現在の空ディレクトリへ `git clone .` で取得。 | 「このフォルダにクローンして」と言われたとき |
| `/github-make-sync`（手動のみ） | 指定した名前で非公開GitHubリポジトリを作成し、`gh` CLIで現在のプロジェクトに `origin` を設定。 | 新規プロジェクトをGitHubに接続したいとき |

---

## 9. マーケティング（オプトイン・47件・未インストール）

**日常の `skills-pack` には含まれない。いまの PC にも入っていない。**  
正本は [skills-pack-marketing](skills-pack-marketing/INSTALL.md)。**パックはリポジトリに置くが、必要なときまで install しない。** 通常の skills 更新では入らない・戻らない。

| 項目 | 内容 |
|------|------|
| 入れるとき | LP・広告・ローンチ等のマーケ制作が必要なときだけ |
| 入れ方 | `skills-pack-marketing/install.ps1`（→ `~/.cursor/skills/` のみ） |
| 置かない先 | `~/.agents/skills/`、原則 `~/.claude/skills/` |
| 外し方 | `~/.cursor/skills/marketingskills/` と `playbooks/playbook-lp-creative/` を削除 |
| 注意 | マーケパックは `~/.cursor/skills/` にカテゴリフォルダごと入る旧方式のまま。日常パック（`~/.agents` 平置き）とは構成が違う |
| 入口（導入後） | `/playbook-lp-creative`、または `/route-playbook`（パック導入済みのときだけ候補に載る） |
| 発火 | 当面すべて手動。一括自動はしない |

前提スキル（`frontend-design` / `canvas-design` / `theme-factory` / `pptx`）は日常パック側（こちらは入っている）。

以下は **marketing パック導入後**に使えるカタログ（手動のみ）。未導入のあいだは参照用。

### 入口 playbook

| コマンド | 内容 | 使いどころ |
|----------|------|-----------|
| `/playbook-lp-creative` | marketingskills（訴求設計）→ `frontend-design` → `canvas-design` → `theme-factory` → `pptx`。Adaptive proposal gate 付き。 | 商品ローンチ、無料特典、セミナー募集の制作一式（**パック導入後**） |

### 戦略・計画系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/marketing-ideas` | 139件の実証済みマーケティング施策ライブラリから、状況・ステージ・リソースに合う施策を提案。 | 「何をすればいいかわからない」「マーケティングのアイデアが欲しい」とき |
| `/marketing-loops` | 週次SEOスキャン、広告疲労チェック、解約シグナル監視など、AIエージェントが一定周期で回す「マーケティングループ」の設計・スケジューリング。 | 一度きりでなく継続的に回る仕組みを作りたいとき |
| `/marketing-plan` | fCMOレベルの、AARRR構造・139のアイデアライブラリ・17項目監査ルーブリックを組み込んだ包括的な12ヶ月マーケティングプランを生成。 | クライアントや自社の本格的な成長計画・GTMプランが欲しいとき |
| `/marketing-psychology` | アンカリング・社会的証明・希少性・損失回避などの心理原則・メンタルモデルをマーケティングに応用。 | 「なぜ人は買うのか」を踏まえた施策・訴求を考えたいとき |
| `/product-marketing` | プロダクトマーケティングの共通コンテキスト文書（`.agents/product-marketing.md`）を作成・更新。他の全マーケティングスキルが参照する起点。 | 新規プロジェクトでマーケティング系スキルを使う前に最初にやる |

### コピー・コンテンツ系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/content-research-writer` | （[§6](#6-デザインコンテンツ制作6件) 参照）リサーチ付き執筆 | — |
| `/content-strategy` | 何を書くべきかのトピック選定・コンテンツピラー・エディトリアルカレンダー計画。 | 「何を書けばいいかわからない」ときの戦略レイヤー |
| `/copy-editing` | 既存コピーの編集・レビュー・改善（リライトではなく強化）。1回のパスで1観点に集中。 | すでにあるコピーを磨きたい、古くなったコンテンツを更新したいとき |
| `/copywriting` | ホームページ・LP・料金・機能ページ等のマーケティングコピーを新規作成・改善。 | 「コピーを書いて」「もっと魅力的に」と言われたとき |
| `/doc-coauthoring` | （[§2](#2-ドキュメントデータ処理10件) 参照）文書の共同執筆ワークフロー | — |
| `/edit-article` | （[§6](#6-デザインコンテンツ制作6件) 参照）記事の構造編集 | — |

### 広告・クリエイティブ系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/ad-creative` | 見出し・説明文・本文などの広告クリエイティブを量産・反復生成。 | 「広告文のバリエーションが欲しい」とき |
| `/ads` | Google/Meta/LinkedIn/X等の有料広告キャンペーン戦略・ターゲティング・入札・最適化。 | 広告キャンペーンの立ち上げ・改善相談 |
| `/image` | ブログヒーロー・SNS画像・製品モックアップ等のマーケティング画像をAI生成・最適化。 | マーケティング用の画像を作りたいとき |
| `/social` | LinkedIn/X/Instagram/TikTok等のSNSコンテンツ作成・スケジューリング・ソーシャルリスニング。 | SNS投稿の作成・トレンド監視・エンゲージメント戦略 |
| `/video` | AIツールやプログラマティックフレームワークでマーケティング動画を制作。 | 製品デモ、説明動画、SNS動画を作りたいとき |

### コンバージョン最適化系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/cro` | LP・料金ページ・フォーム等のコンバージョン率最適化分析と改善提案。 | 「このページのCVRが低い」「改善してほしい」とき |
| `/offers` | オファー自体の設計（価値訴求、ボーナス、保証、緊急性、命名、支払い構造）。 | サービス・コース・高額商材のオファー作り |
| `/onboarding` | サインアップ後のオンボーディング・アクティベーション・初回体験の最適化。 | 「登録はされるが使われない」とき |
| `/paywalls` | アプリ内ペイウォール・アップグレード画面・アップセルモーダルの設計最適化。 | 無料→有料転換の画面を作りたいとき |
| `/popups` | ポップアップ・モーダル・スライドイン・バナーの設計最適化。 | メール獲得ポップアップ、離脱防止オーバーレイなど |
| `/pricing` | SaaS料金・パッケージング・マネタイズ戦略設計。 | 料金プランの設計・見直し相談 |
| `/signup` | サインアップ・登録・トライアル開始フローの離脱削減・完了率向上。 | 登録フローがうまく機能していないとき |

### メール・SMS系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/cold-email` | 返信率を高めるB2Bコールドメールとフォローアップ連続文の作成。 | 新規開拓・営業メールを書きたいとき |
| `/emails` | ドリップ・ナーチャリング・ライフサイクルなど自動化メールシーケンス設計。 | ウェルカムメール、再エンゲージメール等の設計 |
| `/sms` | ウェルカム・カート放棄・購入後・ウィンバック等のSMS/MMSマーケティング設計。 | SMS施策を計画・構築したいとき |

### 分析・実験系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/ab-testing` | A/Bテスト・実験の設計、実験バックログ運用。 | 「どちらのバージョンが良いか検証したい」とき |
| `/analytics` | GA4等の計測・トラッキング実装の設定・改善・監査。 | 「イベントが計測できているか確認したい」とき |
| `/competitor-profiling` | 競合URLリストから構造化された競合プロファイルを作成。 | 複数の競合を深く調査したいとき |
| `/customer-research` | 顧客インタビュー・レビュー・チケット分析からインサイトを抽出、または新規に外部調査。 | 顧客の声を分析したい、ペルソナを作りたいとき |

### SEO・発見性系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/ai-seo` | ChatGPT/Perplexity/AI Overviews等のAI検索・AI回答内で引用されるための最適化。 | AI検索エンジンでの露出を高めたいとき |
| `/aso` | App Store / Google Playのアプリストア最適化診断。 | アプリのストア掲載を改善したいとき |
| `/directory-submissions` | スタートアップ/SaaS/AI向けディレクトリへの登録戦略（被リンク・発見性）。 | Product Hunt等のディレクトリ登録を計画したいとき |
| `/programmatic-seo` | テンプレートとデータでSEO用ページを大量生成。 | 都市名×キーワード等、パターン化されたページを量産したいとき |
| `/schema` | schema.org構造化データ・JSON-LDの実装。 | リッチリザルト表示のための構造化データ追加 |
| `/seo-audit` | サイトのSEO問題の診断・技術的SEOレビュー。 | 「ランキングが落ちた」「SEOを見てほしい」とき（曖昧な相談でもまずこれ） |
| `/site-architecture` | サイトのページ階層・ナビゲーション・URL構造・内部リンクの計画。 | サイト全体の構成を設計・見直ししたいとき |

### 獲得・アウトバウンド系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/co-marketing` | 共同マーケティングパートナーの発掘・共同キャンペーン企画。 | 他社との協業施策を考えたいとき |
| `/community-marketing` | Discord/Slackコミュニティの立ち上げ・成長戦略。 | コミュニティ主導成長を仕掛けたいとき |
| `/free-tools` | リード獲得・SEO・認知向上のための無料ツール企画。 | 無料計算機・診断ツール等で集客したいとき |
| `/launch` | プロダクトローンチ・機能発表・リリース戦略。 | 新機能・新商品の発表を計画したいとき |
| `/lead-magnets` | メール獲得のためのダウンロード資料（ebook、チェックリスト等）企画。 | リードマグネットを作りたいとき |
| `/prospecting` | B2B SaaS/一般B2B/地域中小企業向けの見込み客リスト構築・選定。 | アウトバウンド用のリードリストを作りたいとき |
| `/public-relations` | プレスリリース・記者アウトリーチ・アーンドメディア戦略。 | メディア掲載を狙いたいとき |
| `/referrals` | 紹介プログラム・アフィリエイトプログラムの設計最適化。 | 既存顧客からの紹介を増やす仕組みを作りたいとき |

### 収益・営業系

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/churn-prevention` | 解約防止フロー・セーブオファー・支払い失敗の回収施策設計。 | 解約率が高い、キャンセルフローを作りたいとき |
| `/competitors` | 競合比較ページ・オルタナティブページの作成（SEO＋営業支援）。 | 「vs競合」「〜の代替」ページを作りたいとき |
| `/revops` | リードスコアリング・ルーティング・営業引き渡しプロセスの設計。 | マーケ→営業の引き渡しが機能していないとき |
| `/sales-enablement` | 営業デッキ・1ページ資料・反論対応集・デモ台本の作成。 | 営業チーム向け資料を作りたいとき |

---

## 補足

- **日常配布**は `skills-pack/`。件数と振り分けの正本は `skills-pack/MANIFEST.json`。別 PC では `skills-pack/引き継ぎ.md` の一言をエージェントに送るだけ。
- **Claude Code** は `skills-pack/install-claude.ps1` → `~/.claude/skills/`（平置き・除外9で48件）。`~/.agents` はこちらでは触らない（`install.ps1` の管轄）。`install.ps1` の結果を手コピーしない。
- **マーケ**は `skills-pack-marketing/` に正本があるが **デフォルト非インストール**。[INSTALL.md](skills-pack-marketing/INSTALL.md) 参照。誤って入れたら `marketingskills/` と `playbook-lp-creative/` を削除。
- **設定画面と `/` メニューで件数が違うとき:** 同名スキルが複数 root にある。設定画面は名前で重複排除するが `/` メニューはしないため。Include Third-Party の OFF では `~/.agents` 由来の重複は直らない。詳細は [skills-pack/skills重複処理.md](skills-pack/skills重複処理.md)。
- **Office スキル（docx / xlsx / pptx）** は Python ライブラリが前提（`pip install python-docx openpyxl python-pptx`）。PDF と画像は Cursor がネイティブに読めるので、`pdf` スキルは結合・分割・フォーム入力・OCR 用。
- **playbook の使い方:** 入口は `/route-playbook`、または既知なら `/playbook-*` 直呼び。どちらも最初に適応プラン → `GO` / `通しで`。
- **重複回避**は [skills-pack/引き継ぎ.md](skills-pack/引き継ぎ.md) と [skills重複処理.md](skills-pack/skills重複処理.md)。
- **GWS** は PC ごとに `gws auth login`。skills-pack に OAuth は含まれない。
- **Obsidian** は `obsidian-vault`（`D:\vault`）＋ `obsidian-markdown` ＋ `json-canvas`。vault を移したらパス更新。
- **アプリ台帳** は `app-tech-inventory`（①棚卸し＋直近ダイジェスト）→ 未反映があればバッチ末に `doc-maint`（README限定・GO必須）→ ③の更新通知マッチングは別工程。
- **`skills-cursor/`**（Cursor組み込み）は本一覧に含めない。触らない。
- 各スキルの原文は該当パック内 `SKILL.md` の `description:` を参照。
