# Cursor グローバルスキル一覧（日常パック）

取得日: 2026-07-28  
**いま入っているもの（この PC）:**

| 区分 | 件数 | 場所 |
|------|------|------|
| 日常 `skills-pack` | **55** | `~/.cursor/skills/`（正本） |
| この PC のみの追加 | **2** | `brainstorming-devils` / `brainstorming-persona`（パック外） |
| Cursor 組み込み | **約20** | `~/.cursor/skills-cursor/`（本一覧対象外・触らない） |
| Skills UI 表示 | **約76** | 日常57 + 組み込み − 非表示1件程度 |
| マーケ | **0（未導入）** | カタログは [marketing-skills一覧.md](marketing-skills一覧.md) |

**運用方針**

| 項目 | 内容 |
|------|------|
| 日常 | `skills-pack/` → `install.ps1` で `~/.cursor/skills/` |
| Claude / Agents | 同パックを `install-claude.ps1` で `~/.claude/skills/` と `~/.agents/skills/` に平置き（除外10あり → 各45件） |
| マーケ | `skills-pack-marketing/` は**作るが入れない**。必要時だけ install（Cursor のみ）。詳細は [marketing-skills一覧.md](marketing-skills一覧.md) |
| プロジェクト内 | `.cursor/skills/` は使わない |
| 件数の膨張 | Cursor の **Include Third-Party Plugins, Skills, and Other Configs** が ON だと `~/.claude` 等も合算され 100件超に見える → **OFF 推奨** |

**凡例**

- **コマンド**: `/` で呼び出すときの名前
- **手動のみ**: `disable-model-invocation: true`。会話から自動選択されず、明示的に呼ぶ必要がある
- **使いどころ**: どんな場面・キーワードで出すべきか

日常の生データ: [skills-pack/MANIFEST.json](skills-pack/MANIFEST.json)（55件）  
マーケのカタログ: [marketing-skills一覧.md](marketing-skills一覧.md) / [skills-pack-marketing/MANIFEST.json](skills-pack-marketing/MANIFEST.json)

---

## 目次

1. [オーケストレーター（playbooks・7件）](#1-オーケストレーターplaybooks7件)
2. [ドキュメント／データ処理（10件）](#2-ドキュメントデータ処理10件)
3. [Google Workspace 連携（3件）](#3-google-workspace-連携3件)
4. [設計・開発ワークフロー（Superpowers 系・12件）](#4-設計開発ワークフローsuperpowers系12件)
5. [独自の開発系スキル（11件）](#5-独自の開発系スキル11件)
6. [デザイン・コンテンツ制作（5件）](#6-デザインコンテンツ制作5件)
7. [ナレッジ管理・リサーチ（4件）](#7-ナレッジ管理リサーチ4件)
8. [GitHub / Git / デバッグ（3件）](#8-github--git--デバッグ3件)
9. [この PC のみの追加（2件・パック外）](#9-この-pc-のみの追加2件パック外)
10. [マーケティング（オプトイン・別紙）](#10-マーケティングオプトイン別紙)

---

## 1. オーケストレーター（playbooks・7件）

**手動のみ。日常パックに含まれるのはルーター1＋台本6。** 中身のスキル自体は自動で連鎖しない。

**入口:** どれを使うか分からなければ `/route-playbook`。要求に合う台本＋適応スケッチを提案し、`GO` 後に該当 playbook へ渡す。  
**各 playbook:** 起動直後に **Adaptive proposal gate**（必須/任意/スキップ・通し/チェックポイント）を出し、承認まで作業しない。スキップした Step は Done when から外す。

| コマンド | 内容 | 使いどころ |
|----------|------|-----------|
| `/route-playbook` | 要求を見て最適な `/playbook-*` を1つ（＋代替）提案し、適応スケッチを出して `GO` 待ち。実行はしない。マーケ未導入なら `playbook-lp-creative` は候補から外すか導入を促す。 | 「どのplaybook？」「台本を選んで」「記事書いて／見積まとめて」など入口が曖昧なとき |
| `/playbook-fable5-7day` | `skill-creator` → `brainstorming` → `grill-me` → `verification-before-completion` → `systematic-debugging`。業務棚卸しからスキル作成・設計・穴埋め・QA・デバッグ。 | 自分の業務 OS を作り直したい／スキル基盤を整えたい |
| `/playbook-article-production` | `content-research-writer` → `doc-coauthoring` → `edit-article` →（任意・**marketing パック導入時のみ**訴求調整）。 | X投稿・note記事・メルマガ・セミナー告知文 |
| `/playbook-document-data` | `pdf`/`docx`/`xlsx` 取込・構造化（Phase 1）→ 任意で `gws`（Phase 2）。**Firecrawl は明示指示がない限り使わない。** | 見積・請求・契約の整理、Excel/Word 比較表、Drive 資料 |
| `/playbook-mini-webapp` | `to-prd` → `frontend-design` → `web-artifacts-builder` → `webapp-testing` → `verification-before-completion`。 | 社内管理表・フォーム・簡易ダッシュボード |
| `/playbook-app-improvement` | `systematic-debugging` → `improve-codebase-architecture` → `requesting-code-review` → `react-best-practices`（非 React はスキップ可）。 | 再発バグ、複雑化した既存アプリ |
| `/playbook-research-assets` | `notebooklm` → `obsidian-vault`（＋任意で markdown / canvas）→ `content-research-writer`。 | 散在ナレッジの資産化 |

`/playbook-lp-creative` は日常パック外 → [marketing-skills一覧.md](marketing-skills一覧.md)。

---

## 2. ドキュメント／データ処理（10件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/pdf` | PDF のテキスト・表抽出、結合・分割、回転、透かし、新規作成、フォーム入力、暗号化/復号、画像抽出、スキャンPDFのOCR。 | 「.pdf」に言及、または PDF を作りたい／読みたい／編集したいとき |
| `/docx` | Word 文書（.docx）の作成・読取・編集。目次・見出し・ページ番号・レターヘッド付き文書、画像挿入・置換、検索置換、変更履歴・コメント対応。 | 「Wordドキュメント」「.docx」「レポート」「メモ」「レター」「テンプレート」の作成・編集依頼 |
| `/xlsx` | 既存/新規の .xlsx・.xlsm・.csv・.tsv の読取・編集・修正（列追加、数式計算、書式設定、グラフ化、汚いデータの整形）。成果物は必ずスプレッドシート。 | 「このExcelを直して」「スプレッドシートを作って」など、成果物がスプレッドシートである依頼 |
| `/pptx` | .pptx が入出力どちらかに関わる全作業。スライド作成、テキスト抽出、既存プレゼン編集、テンプレート/レイアウト/スピーカーノート操作。 | 「デッキ」「スライド」「プレゼン」「.pptx」に言及されたら常に使う |
| `/theme-factory` | スライド・文書・レポート・LP等に一貫したテーマ（色・フォント）を適用。10種のプリセットテーマ or 新規生成。 | 成果物のトンマナを統一したいとき。marketing パックの `playbook-lp-creative` でも使用 |
| `/doc-coauthoring` | 文書・提案書・技術仕様・意思決定文書を「文脈収集→推敲・構造化→読者テスト」の3段階で共同執筆。 | 「ドキュメントを書きたい」「提案書を作りたい」「PRDを書きたい」など、ある程度分量のある文章作成 |
| `/doc-maint` | リポジトリの README / docs を監査・整理・統合・鮮度確認。コードは触らず、証拠に基づく正本ドキュメントに再編。`dev` ブランチ前提。 | 「READMEを直して」「docsを整理して」「ドキュメントが古い」「重複を消して」「オンボーディングを分かりやすく」 |
| `/skill-creator` | 新規スキル作成、既存スキルの編集・最適化、評価(eval)実行、性能ベンチマーク。 | スキルを新規作成したい／SKILL.mdの書き方を聞かれたとき |
| `/promote-skill` | スキル作成直後の2段確認: global に入れる？→ skills-pack に同期する？。skills-maker パス未検出時は聞いて、検証前は書かない。 | create-skill / skill-creator 完了後、「globalに入れる」「skills-packに同期」 |
| `/improve-codebase-architecture`（手動のみ） | コードベースをスキャンして「深化の余地」をHTMLレポートで可視化し、選んだ項目についてgrill-me形式で深掘り。 | 過去のコードの複雑化を解消したい、リファクタリング候補を洗い出したい |

---

## 3. Google Workspace 連携（3件）

**前提: `gws` CLI (`@googleworkspace/cli`) のインストールと OAuth 認証（`gws auth login`）が別途必要。PCごとの設定。**

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/gws-docs` | Google Docs の読み書き（`gws docs` コマンドのラッパー）。 | Google ドキュメントの内容を読む・編集する依頼 |
| `/gws-sheets` | Google Sheets の読み書き（`gws sheets` コマンドのラッパー）。 | Google スプレッドシートの内容を読む・編集する依頼 |
| `/gws-drive` | Google Drive のファイル・フォルダ・共有ドライブ管理（`gws drive` コマンドのラッパー）。 | Drive 上のファイル検索・一覧・整理の依頼 |

---

## 4. 設計・開発ワークフロー（Superpowers系・12件）

[obra/superpowers](https://github.com/obra/superpowers) から導入。**`test-driven-development` と `writing-plans` はローカル改良版を採用しており、Superpowers版は導入していない**（重複防止）。

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/using-superpowers` | スキルシステムの使い方ブートストラップ。「1%でも関連しそうならスキルを必ず使う」という原則を強制。 | セッション開始時（自動判定用の基盤スキル） |
| `/brainstorming` | 創造的作業（機能追加・コンポーネント作成・挙動変更）の**前に必ず**要件と設計を対話的に探索。承認なしに実装させない強いゲート。 | 何か新しく作る・変更する前段階。「これは簡単すぎて設計不要」という思い込みへの対抗策 |
| `/using-git-worktrees` | 既存の隔離状態を検知した上で、feature作業やプラン実行前に隔離ワークスペース（git worktree等）を用意。 | 設計承認後、本体を汚さず並行作業したいとき |
| `/executing-plans` | 書かれた実装プランを読み込み、批判的にレビューしてからチェックポイント付きでタスクを実行。 | すでにプランファイルがあり、別セッションで実行したいとき |
| `/subagent-driven-development` | タスクごとに新規サブエージェントを起動し、実装後に毎回レビュー、最後に全体レビュー。 | 独立したタスクが並ぶ実装プランを、今のセッション内で高品質に進めたいとき |
| `/dispatching-parallel-agents` | 2つ以上の独立したタスク（別ファイル・別バグ等）を並列サブエージェントで同時処理。 | 複数の無関係な失敗やタスクを同時に片付けたいとき |
| `/requesting-code-review` | 完了したタスク・大きな機能実装後・マージ前に、専用コンテキストを持つレビュアーサブエージェントへレビュー依頼。 | タスク完了時、マージ前、行き詰まったときの新しい視点 |
| `/receiving-code-review` | レビュー指摘を鵜呑みにせず、技術的に検証してから対応。読む→理解→検証→評価→応答→実装の順で処理。 | コードレビューのフィードバックを受け取ったとき |
| `/systematic-debugging` | バグ・テスト失敗・想定外挙動に遭遇したら、**必ず根本原因調査を先に完了してから**修正提案する4段階プロセス。 | あらゆるバグ調査の前段階。「とりあえず直す」を禁止 |
| `/verification-before-completion` | 「完了した」「直った」と主張する前に、検証コマンドを実際に実行し出力で裏付ける。証拠なき完了宣言を禁止。 | 完了報告・コミット・PR作成の直前 |
| `/finishing-a-development-branch` | 実装完了・テスト通過後、マージ/PR/破棄などの選択肢を整理して提示し、選んだワークフローを実行。 | 開発ブランチの後始末をどうするか決めるとき |
| `/writing-skills` | 新規スキルの作成・編集・デプロイ前の検証。TDD（RED-GREEN-REFACTOR）をドキュメント作成に応用。 | 新しいスキルを書く、既存スキルを直す、公開前の動作確認 |

---

## 5. 独自の開発系スキル（11件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/new-project`（手動のみ） | Hidem プロジェクトキット（Web/Tauri/MAUI）で新規グリーンフィールドを CLI 対話式に scaffold。`PROJECT.md` / `.project_rules/MASTER_PROTOCOL.md` 等を生成。 | 新規アプリ・新規プロジェクト立ち上げ時（Day 0 の1回のみ）。既存プロジェクトの機能追加・バグ修正では使わない |
| `/test-driven-development` | RED-GREEN-REFACTORのTDDを実装前に徹底。ローカル改良版（Superpowers本体＋マルチスタックテストコマンド表付き）。 | 機能追加・バグ修正・リファクタリング前。「TDDで」「テストファーストで」と言われたとき |
| `/writing-plans` | ファイルパス・コード断片・検証手順まで含めた実装プランを、コーディング前に作成。ローカル Cursor 向け Adapt 版。 | 仕様が複数ステップにわたる非自明な機能に着手する前 |
| `/webapp-testing` | Cursorのブラウザ MCP または Playwright スクリプトでローカル Web アプリをテスト。ユニット/E2E(IDE)/E2E(スクリプト)の使い分け表あり。 | 「アプリをテストして」「UIを確認して」、フロントエンドの動作検証全般 |
| `/react-best-practices`（`vercel-react-best-practices`） | Vercel Engineering によるReact/Next.jsパフォーマンス最適化ガイド（8カテゴリ70ルール）。 | React/Next.jsのコンポーネント作成・データフェッチ実装・パフォーマンスレビュー・リファクタリング |
| `/web-artifacts-builder` | React 18 + TypeScript + Vite + Tailwind + shadcn/ui で、状態管理やルーティングを含む多コンポーネントのHTMLアーティファクトを構築。 | 単純な単一ファイルHTML/JSXでは足りない、複雑なWebアーティファクトを作りたいとき |
| `/to-prd`（手動のみ） | 今の会話をヒアリングなしでそのままPRDに合成し、Issueトラッカーへ公開。 | すでに会話で要件が固まっており、そのままPRD化したいとき |
| `/to-issues`（手動のみ） | プラン・仕様・PRDを、独立して着手可能な「トレーサーバレット」の垂直スライスIssueに分解。 | PRDや設計書を実装可能な単位のIssueに分割したいとき |
| `/git-guardrails-claude-code` | 危険なGitコマンド（push、reset --hard、clean、branch -D等）を実行前にブロックするフックを設定。 | 誤操作防止のガードレールを設定したいとき |
| `/session-recap`（手動のみ） | 今の会話を `備忘録.md` の日付エントリにする（決定・調査・次のTODO）。コード変更履歴用の `変更履歴.md` には書かない。 | 「まとめて」「備忘録に残して」「このやり取りを記録して」と明示されたときだけ |
| `/chat-handoff`（手動のみ） | 別PCで続きをやるための引き継ぎメモ（リポジトリ直下の日付付き `質疑応答M-D.MD`）。Cursor チャット履歴は端末ローカルのため、持ち運び用の正本をファイルに落とす。 | 「別PC用に残して」「引き継ぎ書いて」「質疑応答に落として」「続きは別端末で」と明示されたとき。通常の備忘録は `/session-recap` |

---

## 6. デザイン・コンテンツ制作（5件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/frontend-design` | テンプレート感のない、意図を持った視覚デザインの方向性（配色・タイポグラフィ・レイアウト）を決める設計思想ガイド。 | 新規UI構築、既存UIの作り直し、「他と被らないデザインにしたい」とき |
| `/canvas-design` | .png/.pdfで独自のビジュアルアート（ポスター・作品・デザイン）を、デザイン哲学の作成→視覚表現の2段階で制作。 | ポスター、アート作品、静的なビジュアルデザインを作りたいとき |
| `/edit-article`（手動のみ） | 記事を見出しで章分けし、各章を明確さ・一貫性・流れの観点で書き直す（1段落最大240字）。 | 記事の下書きを編集・改善・推敲したいとき |
| `/content-research-writer` | リサーチ・引用付与・フック改善・アウトライン反復・セクションごとのリアルタイムFBで、執筆をパートナー作業に変える。 | ブログ・記事・ニュースレター・技術文書の執筆、根拠付きの文章を書きたいとき |
| `/grill-me` | プラン・設計について執拗に一問一答で質問し、決定木の分岐を一つずつ潰して共通理解に至る。各質問に推奨回答も提示。 | 「grill me」「プランを詰めて」と言われたとき、設計の穴を潰したいとき |

---

## 7. ナレッジ管理・リサーチ（4件）

Obsidian 系は **3スキル連携**。`obsidian-vault` が vault パス（`D:\vault`）と運用、`obsidian-markdown` が文法、`json-canvas` が `.canvas` 俯瞰。

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/notebooklm`（`notebooklm-skill`） | Google NotebookLM のノートブックにブラウザ自動化で問い合わせ、Geminiの根拠付き回答を取得。ハルシネーションを大幅抑制。 | NotebookLMのURLを共有された、「自分のNotebookLMに聞いて」と言われたとき |
| `/obsidian-vault` | `D:\vault` 内のノートを wikilink・インデックスノートで検索・作成・整理。vault パスと命名規則の正本。 | Obsidianでノートを探す・作る・整理したいとき |
| `/obsidian-markdown` | callout、frontmatter（properties）、embed、wikilink 等の Obsidian Flavored Markdown 文法。kepano/obsidian-skills 由来。 | Obsidian ノートの書式・callout・メタデータを正確に書きたいとき |
| `/json-canvas` | `.canvas` ファイル（ノード・エッジ・グループ）の生成・編集。`D:\vault\canvas\` 推奨。kepano/obsidian-skills 由来。 | マインドマップ、フローチャート、Index の視覚俯瞰を Canvas で作りたいとき |

執筆パートナーは `/content-research-writer`（[§6](#6-デザインコンテンツ制作5件)）。

---

## 8. GitHub / Git / デバッグ（3件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/github-make-sync`（手動のみ） | 指定した名前で非公開GitHubリポジトリを作成し、`gh` CLIで現在のプロジェクトに `origin` を設定。 | 新規プロジェクトをGitHubに接続したいとき |
| `/git-in-clone`（手動のみ） | 指定したGitHubリポジトリを現在の空ディレクトリへ `git clone .` で取得。 | 「このフォルダにクローンして」と言われたとき |
| `/debug-allrun`（手動のみ） | デバッガ付きで起動し、サイレントなデータ破損・非同期レース・分岐ミスという3種の隠れバグを能動的に探索・自動修正・報告。 | `/debug-allrun` 明示呼び出し時。「クラッシュしないから安全」を信用しない徹底デバッグ |

`/git-guardrails-claude-code` は [§5](#5-独自の開発系スキル11件)。

---

## 9. この PC のみの追加（2件・パック外）

**`skills-pack/MANIFEST.json` には含まれない。** 別 PC へ `install.ps1` しても入らない。このマシンの `~/.cursor/skills/brainstorming/` 配下にだけある。

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/brainstorming-persona`（手動のみ） | 専門家ペルソナを回して多角的にブレスト。単一視点の盲点を潰す。実装はしない。 | 「複数の専門家視点で」「ペルソナでブレストして」 |
| `/brainstorming-devils`（手動のみ） | 提案をデビルズアドボケイト視点で攻撃し、前提・リスク・反例を洗い出す。実装はしない。 | 「ストレステストして」「悪魔の代弁者で」「敵対レビューして」 |

パックに載せるなら `promote-skill` / 手動で `skills-pack` へ同期が別途必要。

---

## 10. マーケティング（オプトイン・別紙）

日常パック外・**いまの PC には未インストール（0件）**。  
カタログ・入れ方・全47件の表は **[marketing-skills一覧.md](marketing-skills一覧.md)** を参照。

---

## 補足

- **日常配布**は `skills-pack/`（MANIFEST **55件**）。別 PC では `skills-pack/引き継ぎ.md` の一言をエージェントに送るだけ。
- **この PC の `~/.cursor/skills/`** は 55 + ローカル2 = **57件**。Skills UI の約76は組み込み `skills-cursor` 合算。
- **Claude / Agents** は `skills-pack/install-claude.ps1` → `~/.claude/skills/` と `~/.agents/skills/`（平置き・除外10で各45件）。除外: `docx` `pdf` `pptx` `xlsx` `skill-creator` `using-superpowers` `requesting-code-review` `receiving-code-review` `verification-before-completion` `using-git-worktrees`。
- **マーケ**は [marketing-skills一覧.md](marketing-skills一覧.md)。デフォルト非インストール。
- **件数 100超に見えるとき:** Cursor Settings → Rules, Skills, Subagents → **Include Third-Party... を OFF**。`~/.claude` は消さない（Claude Code 用）。詳細は [skills-pack/skills重複処理.md](skills-pack/skills重複処理.md)。
- **playbook の使い方:** 入口は `/route-playbook`、または既知なら `/playbook-*` 直呼び。どちらも最初に適応プラン → `GO` / `通しで`。
- **重複回避**は [skills-pack/引き継ぎ.md](skills-pack/引き継ぎ.md) と [skills重複処理.md](skills-pack/skills重複処理.md)。
- **GWS** は PC ごとに `gws auth login`。skills-pack に OAuth は含まれない。
- **Obsidian** は `obsidian-vault`（`D:\vault`）＋ `obsidian-markdown` ＋ `json-canvas`。vault を移したらパス更新。
- **`skills-cursor/`**（Cursor組み込み）は本一覧に含めない。触らない。
- 各スキルの原文は該当パック内 `SKILL.md` の `description:` を参照。
