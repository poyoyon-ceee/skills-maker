# 手動のみスキル一覧（`disable-model-invocation: true`）

取得日: 2026-08-19  
出典: [skills一覧.md](skills一覧.md) / [skills-pack/MANIFEST.json](skills-pack/MANIFEST.json)

**対象:** 日常 `skills-pack` のうち、会話から自動選択されず **明示呼び出しが必要なスキルのみ**（**18件**）。  
マーケ（`skills-pack-marketing`）はパック全体が手動だが **未インストール**のため本一覧には含めない → [marketing-skills一覧.md](marketing-skills一覧.md)

**凡例**

- **コマンド**: `/` で呼び出すときの名前
- **手動のみ**: `disable-model-invocation: true`
- **使いどころ**: どんな場面・キーワードで出すべきか
- **各カテゴリ内の並び**: コマンド名のアルファベット順

自動発火ありのスキル（GWS・Superpowers・ナレッジ等）はここには載せない。全体は [skills一覧.md](skills一覧.md)。

---

## 目次

1. [オーケストレーター（playbooks・7件）](#1-オーケストレーターplaybooks7件)
2. [ドキュメント／データ処理（1件）](#2-ドキュメントデータ処理1件)
3. [独自の開発系スキル（6件）](#3-独自の開発系スキル6件)
4. [デザイン・コンテンツ制作（2件）](#4-デザインコンテンツ制作2件)
5. [GitHub / Git 運用（2件）](#5-github--git-運用2件)

---

## 1. オーケストレーター（playbooks・7件）

**カテゴリ全体が手動のみ。** 日常パックに含まれるのはルーター1＋台本6。中身のスキル自体は自動で連鎖しない。

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

`/playbook-lp-creative` は日常パック外・**未インストール**（マーケパック側・手動）。

---

## 2. ドキュメント／データ処理（1件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/improve-codebase-architecture` | コードベースをスキャンして「深化の余地」をHTMLレポートで可視化し、選んだ項目についてgrill-me形式で深掘り。 | 過去のコードの複雑化を解消したい、リファクタリング候補を洗い出したい |

---

## 3. 独自の開発系スキル（6件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/00` | メッセージ先頭の `/00` で、そのターンだけ Superpowers 強制ワークフローを無効化。依頼本文は通常どおり処理。次のメッセージへは引き継がない。 | Superpowers を使わず、今の依頼だけ素早く処理したいとき。文章中やコード内の `/00` では発動しない |
| `/chat-handoff` | 別PCで続きをやるための引き継ぎメモを、リポジトリ直下の `質疑応答M-D.MD` に作成・追記。結論・決定・未解決TODOを残す。Cursor チャット履歴は端末に残る前提。 | 「別PC用に残して」「引き継ぎ書いて」「質疑応答に落として」「続きは別端末で」と明示されたとき。通常の備忘録は `/session-recap` |
| `/new-project` | 空ディレクトリ向け scaffold。CLI 対話。必須は README。Hidem プロファイルは選択式。既存ファイルは上書きしない。 | `project-foundation` が新規と判定したとき。既存リポジトリでは使わない |
| `/session-recap` | 今の会話を `備忘録.md` の日付エントリにする（決定・調査・次のTODO）。コード変更履歴用の `変更履歴.md` には書かない。 | 「まとめて」「備忘録に残して」「このやり取りを記録して」と明示されたときだけ |
| `/to-issues` | プラン・仕様・PRDを、独立して着手可能な「トレーサーバレット」の垂直スライスIssueに分解。 | PRDや設計書を実装可能な単位のIssueに分割したいとき |
| `/to-prd` | 今の会話をヒアリングなしでそのままPRDに合成し、Issueトラッカーへ公開。 | すでに会話で要件が固まっており、そのままPRD化したいとき |

**handoff vs recap:** 別PC引き継ぎ → `/chat-handoff`（`質疑応答M-D.MD`）。同じPCの備忘 → `/session-recap`（`備忘録.md`）。

---

## 4. デザイン・コンテンツ制作（2件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/debug-allrun` | デバッガ付きで起動し、サイレントなデータ破損・非同期レース・分岐ミスという3種の隠れバグを能動的に探索・自動修正・報告。 | `/debug-allrun` 明示呼び出し時。「クラッシュしないから安全」を信用しない徹底デバッグ |
| `/edit-article` | 記事を見出しで章分けし、各章を明確さ・一貫性・流れの観点で書き直す（1段落最大240字）。 | 記事の下書きを編集・改善・推敲したいとき |

---

## 5. GitHub / Git 運用（2件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/git-in-clone` | 指定したGitHubリポジトリを現在の空ディレクトリへ `git clone .` で取得。 | 「このフォルダにクローンして」と言われたとき |
| `/github-make-sync` | 指定した名前で非公開GitHubリポジトリを作成し、`gh` CLIで現在のプロジェクトに `origin` を設定。 | 新規プロジェクトをGitHubに接続したいとき |

---

## 補足

- **計18件**（playbooks 7 + その他 11）。日常パック（MANIFEST 58件）のうち手動はこれだけ。
- `/project-foundation` は自動発火なので本一覧に含めない。新規判定後の scaffold は `/new-project`。
- 手動スキルはモデルが勝手に選ばない。`/` で明示呼び出しが必要。
- マーケ全件手動・未インストールは [marketing-skills一覧.md](marketing-skills一覧.md)。
- 正本の定義・運用は [skills一覧.md](skills一覧.md)。
