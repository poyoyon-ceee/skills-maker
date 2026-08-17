# Cursor向け引き継ぎ書 — project-foundation / new-project / doc-maint 再設計

日付: 2026-08-16  
対象リポジトリ: `C:\Dev-App\skills-maker`  
対象正本: `skills-pack/`  
状態: 設計方針確定、実装未着手  
読者: Cursor Agentとレビュー担当者

## 0. Cursorへの最重要指示

この文書を読んだ直後に実装を開始しないこと。最初にリポジトリの現状を再確認し、ユーザーから明示的な実装許可を得ること。

現時点で許可されているのは、調査、設計確認、コード差分レベルの実装計画までである。コード、スクリプト、設定、テスト、スキル本体の変更はまだ許可されていない。

作業開始時に必ず実施すること:

1. `C:\Dev-App\skills-maker` が作業ルートであることを確認する。
2. `git status --short --branch` を確認する。
3. 現在確認されている未追跡の `.claude/` をユーザー所有の変更として扱う。
4. `.claude/` を削除、移動、stash、上書き、commit対象へ追加しない。
5. branch作成、commit、push、mergeはユーザーの明示指示がある場合だけ行う。
6. ホーム配下の `~/.agents/skills`、`~/.cursor/skills`、`~/.claude/skills`、`~/.codex/skills`を正本として直接編集しない。
7. スキルの正本は常に`C:\Dev-App\skills-maker\skills-pack`とする。

現状確認時点では、`skills-maker`は`main...origin/main`で、`.claude/`が未追跡である。作業時には必ず再確認すること。

## 1. 目的

現在の`new-project`はHidem project kitの新規生成に特化し、`PROJECT.md`と`.project_rules/MASTER_PROTOCOL.md`を中心にしている。この設計を、一般的な文書管理構造を必須コアとし、Hidem固有規約を選択式プロファイルとして追加できる形へ改める。

同時に、既存プロジェクトの文書を安全に監査・再構成できる共通入口`project-foundation`を追加する。

最終的な利用体験:

```text
project-foundation
├─ 新規プロジェクト → new-project
├─ 既存プロジェクト → doc-maint
└─ 判定不能           → 停止してユーザーへ確認
```

## 2. ユーザーと確定した設計判断

以下は合意済みであり、明確な技術的矛盾が見つからない限り再度選択を求めないこと。

1. `project-foundation`を共通入口として新設する。
2. `new-project`と`doc-maint`の責務は分離したままにする。
3. 一般的な文書管理構造を必須コアにする。
4. Hidem固有規約は選択式プロファイルにする。
5. 既存プロジェクトは「読み取り専用監査 → ユーザー承認 → 適用」の二段階にする。
6. 既存プロジェクトの監査結果は、ユーザー向けには「維持・統合・修正・移動・要確認」の5分類だけを表示する。
7. 詳細な内部判定ラベルごとのファイルやフォルダは作らない。
8. `C:\Dev-App\skills-maker\skills-pack`を唯一の正本とする。
9. 既存の`install.ps1`と`install-claude.ps1`による同期体系を使う。
10. インストール済みグローバルスキルを直接編集しない。
11. スキル変更はRED-GREEN-REFACTORで検証する。
12. 不要なMarkdown、manifest、空プレースホルダーを増やさない。

## 3. 現行構成と確認済みの問題

### 3.1 現在の配布構造

- `skills-pack/install.ps1`
  - portableスキルを`~/.agents/skills/`へ平置きで配布する。
  - Cursor固有スキルだけを`~/.cursor/skills/`へ配布する。
  - 同名重複、stale copy、hash差分を扱う。
- `skills-pack/install-claude.ps1`
  - Claude Code向けに`~/.claude/skills/`へ配布する。
  - Claude組み込みと重複するスキルを除外する。
  - `_claude/`オーバーレイをベースコピー後に適用する。
- `skills-pack/MANIFEST.json`
  - 配布スキルとinstall targetの一覧である。

この体系を壊さず、`project-foundation`をportableスキルとして追加する。

### 3.2 `new-project`が一般標準優先ではない

対象:

- `skills-pack/new-project/SKILL.md`
- `skills-pack/new-project/scripts/FILE_TEMPLATE_SOURCE.md`
- `skills-pack/new-project/scripts/MASTER_PROTOCOL_SOURCE.md`
- `skills-pack/new-project/scripts/scaffold.js`

確認済み:

- `PROJECT.md`が「単一の真実」として扱われている。
- グローバル`CLAUDE.md`を最上位にする記述が共通テンプレートへ入っている。
- ルート`README.md`と`docs/index.md`が必須コアになっていない。
- `Minimal / Standard / Full`によって、必要性ではなくレベル名でAI用文書が増える。
- `docs/AI_REVIEW_PROMPT.md`や`docs/AI_IMPROVEMENT_PROMPT.md`がStandard以上で一律生成される。

### 3.3 上書き防止がSKILLと実装で一致していない

対象:

- `skills-pack/new-project/scripts/lib/writer.js`
- `skills-pack/new-project/scripts/scaffold.js`

`SKILL.md`は競合時に確認・停止するとしているが、`ProjectWriter.writeFile()`は`fs.writeFileSync(fullPath, content, 'utf-8')`で無条件に書き込む。scaffolder本体にも全出力パスを事前検証する処理がない。

既存プロジェクト対応を追加する前に、この不一致をREDテストで再現し、上書き不能な設計へ変更する必要がある。

### 3.4 npm installの偽完了表示

`scaffold.js`は「今すぐ npm install を実行しますか？」と確認したあと、実際にはchild processを実行せず「インストール完了（シミュレーション）」と表示する。

新設計ではnpm installを自動実行しない。生成完了後に、必要なコマンドとして案内するだけにする。将来自動実行を追加する場合は、別の明示承認と実結果の検証が必要。

### 3.5 プラットフォーム中立性が崩れている

`skills-pack/new-project/SKILL.md`の実行パスが`~/.claude/skills/new-project/scripts/scaffold.js`へ固定されている。ベース版と`skills-pack/_claude/new-project/`の役割が曖昧で、共通版がClaude前提になっている。

共通版は固定vendor pathを使わず、ロードされたスキル自身の`scripts/`を解決する。Claude固有差分がなくなった場合は、`_claude/new-project`を残す必要があるか確認し、不要なら削除候補としてユーザーへ提示する。無断削除はしない。

### 3.6 テンプレート正本が二重化している

`skills-pack/new-project/reference.md`は`C:\Dev-App\original-source-maker`等をテンプレート原典としている。一方、ユーザーは`C:\Dev-App\skills-maker`で全スキルを一元管理し、ここから同期する方針を明示した。

確認時点で、`original-source-maker/FILE_TEMPLATE_SOURCE.md`とskills-pack同梱版には5 insertions / 5 deletionsの差分があった。`MASTER_PROTOCOL_SOURCE.md`は同一だった。

新設計では`skills-maker/skills-pack`を正本とする。`original-source-maker`は削除せず、旧原典・比較資料として扱う。`reference.md`の正本説明を更新する。

### 3.7 `doc-maint`は近いが一般化が必要

`skills-pack/doc-maint/SKILL.md`には既存文書の棚卸し、README入口、`docs/index.md`、重複排除、リンク検査がすでにある。

ただし、現行版は`dev` branchを一律に要求する。一般標準では特定branch名を強制せず、既存の`AGENTS.md`、プロジェクト規約、ユーザー指定、現行Git運用の順で判断する。

## 4. 目標構成

```text
skills-pack/
├─ project-foundation/
│  ├─ SKILL.md
│  ├─ references/
│  │  └─ documentation-standard.md
│  └─ scripts/                 # テストで必要性を証明できた場合だけ
│     └─ detect-project.js     # optional
├─ new-project/
│  ├─ SKILL.md
│  ├─ reference.md
│  └─ scripts/
│     ├─ scaffold.js
│     ├─ FILE_TEMPLATE_SOURCE.md
│     ├─ MASTER_PROTOCOL_SOURCE.md
│     └─ lib/
├─ doc-maint/
│  ├─ SKILL.md
│  └─ references/
│     ├─ audit-checklist.md
│     └─ documentation-structure.md
├─ _claude/
├─ MANIFEST.json
├─ install.ps1
└─ install-claude.ps1
```

`project-foundation/scripts/detect-project.js`は推奨案であり、agentだけで確実に判定できる場合は、まずテストでスクリプトの必要性を証明すること。再利用性・決定性が必要なら追加し、不要ならSKILL内の判定規約に留める。YAGNIを優先する。

## 5. 一般文書標準

### 5.1 必須コア

#### ルート`README.md`

すべてのプロジェクトで必須。

- プロジェクト名と目的
- 確認できた現在の状態
- 主な機能
- 最短のセットアップ・実行方法
- 主要な制約
- リポジトリ構成の概要
- 詳細文書へのリンク

READMEは入口に徹し、詳細仕様、長大な設計、ツール固有指示を複製しない。

#### `docs/index.md`

`docs/`に正本文書が1件以上ある場合に必須。

- 文書名
- 何についての正本か
- 状態
- いつ読む文書か

詳細文書が不要な小規模プロジェクトでは作らず、READMEだけで完結させる。

### 5.2 条件付き文書

必要な内容がある場合だけ作る。

```text
docs/
├─ index.md
├─ spec.md
├─ architecture.md
├─ development.md
├─ design/
│  └─ <topic>.md
├─ plans/
│  └─ <topic>.md
└─ decisions/
   └─ <decision>.md
```

- `spec.md`: READMEに収まらない実装済み機能仕様
- `architecture.md`: 現行コンポーネント、境界、重要なデータフロー
- `development.md`: 非自明な開発・テスト・ビルド手順
- `design/`: 未実装または変更予定の設計
- `plans/`: 承認済み設計の実装計画
- `decisions/`: 後から理由を残す価値がある重要決定

`CHANGELOG.md`、`CONTRIBUTING.md`、`SECURITY.md`、`LICENSE`は公開・配布・チーム運用の条件がある場合だけ追加する。

### 5.3 AI向け入口

AIで保守するプロジェクトではルート`AGENTS.md`を推奨する。

- 作業前に読む正本
- 計画と実装の境界
- Gitと未コミット変更の扱い
- commit、push、公開操作の許可条件
- 対象モジュールの文書ハブ

`.cursor/rules/`、`CLAUDE.md`、`.codex/`にはツール固有設定と正本への短いポインタだけを置く。プロジェクト知識を複製しない。

### 5.4 Hidemプロファイル

ユーザーが選択した場合だけ追加する。

```text
PROJECT.md
.project_rules/
└─ MASTER_PROTOCOL.md
```

- `PROJECT.md`: 目的、範囲、非目標、長期的な原則
- `MASTER_PROTOCOL.md`: branch運用、実装開始条件、devVERSION、入店・退店などの作業規約

これらを一般標準そのものとは扱わない。READMEとAGENTSから案内される追加レイヤーとする。

### 5.5 技術構成ファイル

技術的に必要な場合だけ生成する。

- Node/JavaScript: `package.json`
- Rust: `Cargo.toml`
- Python: `pyproject.toml`
- .NET: `*.csproj`

文書整理だけを理由にmanifestを作らない。

### 5.6 文書状態

`docs/index.md`では必要に応じて次の状態を使う。

- `current`
- `approved-design`
- `draft`
- `superseded`
- `historical`

これらは状態ラベルであり、状態別ファイルやフォルダを増やす指示ではない。

### 5.7 禁止する構造

- `spec-final.md`、`spec-new.md`、`latest.md`など正本不明の名前
- 内容のないプレースホルダー文書
- README、PROJECT、AGENTSへの同内容の大量複製
- AI固有フォルダだけにあるプロジェクト知識
- 未実装機能をREADMEで実装済みとして説明
- 実依存や実スクリプトがない`package.json`
- 監査ごとに永続レポートを増やす
- 既存文書を確認せずテンプレートで上書きする

## 6. `project-foundation`の責務

### 6.1 起動条件

新しいアプリ・プロジェクトの立ち上げ、scaffold、既存リポジトリの文書監査・再構成、README/docs/PROJECT/AGENTSの標準化を依頼された場合に発火する。

descriptionには発火条件だけを書き、処理手順の要約を詰め込まない。

### 6.2 判定

`new`候補:

- ソースコード、manifest、README、docsがない。
- Gitだけ初期化済みでも、コミットとプロジェクトファイルがない。

`existing`:

- 既存コミットがある。
- README、ソースコード、docsがある。
- `package.json`、`Cargo.toml`、`*.csproj`などがある。

`ambiguous`:

- 隠しファイルや無関係に見えるファイルだけがある。
- 新規か既存かを安全に決められない。

振り分け:

```text
new       → new-project
existing  → doc-maintの監査モード
ambiguous → 停止し、検出物を示してユーザーへ確認
```

判定だけで書き込みを行わない。

## 7. `new-project`の新フロー

### 7.1 ヒアリング

1. プロジェクト名と目的
2. Web / Tauri / MAUI / 文書基盤だけ
3. Offline / Online / Hybrid
4. 必要な技術モジュール
5. Git運用
6. AIによる保守の要否
7. Hidemプロファイルの要否
8. 生成先

`Minimal / Standard / Full`による文書一括生成は廃止または縮小し、必要性から生成物を決める。

### 7.2 書き込み前プレビュー

全出力パスを確定し、作成予定、Hidemプロファイル、競合を表示する。この時点では変更しない。

### 7.3 競合検査

- 1件でも既存ファイルと衝突したら一括停止する。
- 生成先外へ出るパスを拒否する。
- Windowsでは大文字・小文字だけが異なるパスも衝突として扱う。
- symlink / junction経由で生成先外へ出る場合も拒否する。
- 標準動作として既存ファイルを上書きしない。

### 7.4 ステージング

1. 一時領域へ全ファイルを生成する。
2. プレースホルダー残存を検査する。
3. JSON、TOML、XML等を構文検査する。
4. Markdownリンクを検査する。
5. 必須コアを検査する。
6. 問題がなければ生成先へ反映する。

反映時は操作journalに、その実行が新規作成したファイルとディレクトリだけを記録する。ファイルについては作成直後のhash、size、mtimeも記録する。途中で失敗した場合はjournal記載分だけを逆順に確認し、現在値が作成直後の記録と一致するファイルだけを除去する。値が異なる場合は第三者変更の可能性があるため削除せず、残存パスとして報告する。ディレクトリはこの実行が作成し、かつ空の場合だけ除去する。実行前から存在したファイルとjournalにないパスには触らない。ロックなどで後始末できない場合も成功扱いにせず、残存パスを報告する。完全なatomic renameを保証できない環境では「原子的」と表現しない。

### 7.5 生成物

常に生成:

- `README.md`

条件付き:

- AI保守を選んだ場合の`AGENTS.md`
- 正本文書がある場合の`docs/index.md`
- 必要な`docs/development.md`
- 技術的に必要なmanifestとソース
- Hidemプロファイルの`PROJECT.md`と`MASTER_PROTOCOL.md`

未実装の設計書、実装計画、AIレビュープロンプトは内容がない段階で生成しない。

### 7.6 事後処理

生成ファイル、選択プロファイル、検証結果、次に読む文書、実行可能なセットアップコマンドを報告する。

自動実行しないもの:

- `npm install`
- Git初期化
- commit
- push
- 開発サーバー起動

## 8. `doc-maint`の既存プロジェクトフロー

### 8.1 監査は読み取り専用

監査中はファイル作成・編集・移動・削除、branch変更、stash、commit、push、formatter、package install、自動修正を行わない。

確認対象:

- Git branch、status、未コミット変更
- リポジトリレベルのAI・人間向け指示
- README、docs、設計書、計画書
- manifest、ビルド設定、テスト、CI
- ソース上の実際の機能
- 文書リンクと参照元
- 必要なGit履歴

### 8.2 ユーザー向け監査結果

表示は次の5分類に限定する。

| 分類 | 対応 |
|---|---|
| 維持 | 正本または必要な履歴として残す |
| 統合 | 他の正本へ固有情報を移す |
| 修正 | 古い、または現行実装と矛盾する内容を直す |
| 移動 | 設計、計画、ツール固有文書を適切な場所へ移す |
| 要確認 | 根拠不足でユーザー判断が必要 |

内部では重複、矛盾、stale、planned、historical、orphaned等を判定してよいが、それらを文書ファイルの種類にはしない。

### 8.3 承認

監査結果には、操作、理由、移動先、影響するリンク、復旧可能性を付ける。ユーザーは計画全体または個別操作を承認できる。

監査結果は原則チャットで提示し、監査レポートを自動生成しない。保存要求がある場合だけ既存の`docs/plans/`へ置く。

### 8.4 適用前再検証

- 監査後に対象ファイルが変わっていない。
- 移動先や統合先が新規作成されていない。
- ユーザー所有変更と重ならない。
- 削除候補の固有情報が正本へ保存されている。
- inbound linkの更新先が決まっている。
- 文書以外の変更が含まれない。

不一致があれば該当項目を停止し、計画を更新する。

### 8.5 branch方針

`dev`を一律に強制しない。

1. リポジトリの指示
2. 既存branch運用
3. ユーザー指定
4. 指示がない場合は専用branchを提案

default branchでの変更禁止がある場合は、ユーザー承認後に作業branchへ移る。未コミット変更を勝手にstash、移動、破棄しない。

### 8.6 適用順序

1. 正本文書の作成・更新
2. 固有情報の統合
3. リンク更新
4. 文書移動
5. リンク検査
6. 削除候補の最終確認
7. 削除
8. 全体検証

追跡済み文書はGitから復旧可能であることを確認する。未追跡文書は明示承認なしに削除しない。

### 8.7 Hidemプロファイル

既にある場合は保護し、一般標準の入口から参照できるようにする。存在しない場合は監査結果で選択肢として示し、自動追加しない。

## 9. 実装方針

### Phase 0: 保護とベースライン

- Git状態と未追跡`.claude/`を記録する。
- 現行`new-project`、`doc-maint`、install scripts、MANIFESTを再読する。
- pack同梱テンプレートと旧原典の差分を保存する。
- 既存の自動テスト基盤を確認する。

### Phase 1: REDテスト

実装前に最低限、次の失敗を現行版で再現する。

1. 新規生成でREADMEが欠落する。また、現行scaffolderは`docs/TROUBLESHOOTING.md`等を生成するのに`docs/index.md`を生成しない。
2. Hidem固有規約が一般標準より先に出る。
3. 既存ファイルが上書きされ得る。
4. SKILLの競合停止規約とscaffolder実装が一致しない。
5. npm install未実行なのに完了表示する。
6. 共通SKILLがClaude固定パスを参照する。
7. テンプレート正本がdriftする。

テストを先に書き、期待した理由で失敗することを確認する。失敗を見ずに実装へ進まない。

### Phase 2: `project-foundation`

候補変更:

- Add: `skills-pack/project-foundation/SKILL.md`
- Add: `skills-pack/project-foundation/references/documentation-standard.md`
- Add only if tests justify it: `skills-pack/project-foundation/scripts/detect-project.js`
- Add: router behavior tests

### Phase 3: `new-project`

候補変更:

- Modify: `skills-pack/new-project/SKILL.md`
- Modify: `skills-pack/new-project/reference.md`
- Modify: `skills-pack/new-project/scripts/scaffold.js`
- Modify: `skills-pack/new-project/scripts/lib/writer.js`
- Modify: `skills-pack/new-project/scripts/FILE_TEMPLATE_SOURCE.md`
- Modify: `skills-pack/new-project/scripts/MASTER_PROTOCOL_SOURCE.md`
- Add: collision、path traversal、staging、profile、placeholder、link tests
- Review/remove only after approval: `skills-pack/_claude/new-project/`

### Phase 4: `doc-maint`

候補変更:

- Modify: `skills-pack/doc-maint/SKILL.md`
- Modify: `skills-pack/doc-maint/references/audit-checklist.md`
- Modify: `skills-pack/doc-maint/references/documentation-structure.md`
- Add: audit read-only、approval gate、five-category output tests

### Phase 5: 配布情報

候補変更:

- Regenerate: `skills-pack/MANIFEST.json`
- Modify if needed: `skills-pack/INSTALL.md`
- Modify if needed: root `SETUP.md`
- Modify if needed: `skills一覧.md`
- Keep behavior unless tests require change: `skills-pack/install.ps1`
- Keep behavior unless tests require change: `skills-pack/install-claude.ps1`

スキル件数を文書へ手作業で固定しない。既存文書に件数がある場合はMANIFESTからの生成または検証方法を検討する。

### Phase 6: 同期

1. `skills-maker/skills-pack`の変更とテストを完了する。
2. `scripts/generate-manifest.ps1`を実行する。
3. pack内同名重複を検査する。
4. ユーザー承認後に`skills-pack/install.ps1`を実行する。
5. ユーザー承認後に`skills-pack/install-claude.ps1`を実行する。
6. install先のhash、件数、同名重複、overlay漏れを検証する。

同期は外部状態を変更するため、実装許可とは別に実行前確認を行う。

## 10. 自動テスト要件

外部依存を増やさず、可能ならNode標準`node:test`を使う。テスト配置とpackage manifestは、既存構造を確認して最小にする。

最低限のケース:

| 対象 | 期待 |
|---|---|
| 空ディレクトリ | `new` |
| README、コード、manifestあり | `existing` |
| 判定材料が曖昧 | `ambiguous`で停止 |
| Hidem OFF | README中心の一般構造 |
| Hidem ON | PROJECTとMASTER_PROTOCOLを追加 |
| 既存ファイル競合 | 1件も書かず停止 |
| `../`または絶対パス | 生成先外へ書かず拒否 |
| symlink / junction escape | 拒否。Windows実機で作成権限がない場合はresolver単体テストを必須とし、実機試験のskipを明示する |
| プレースホルダー残存 | 反映前に失敗 |
| staging失敗 | 既存内容を保持 |
| 既存監査 | ファイル変更ゼロ |
| 一部承認 | 承認項目だけ適用 |
| 未追跡削除候補 | 明示承認なしでは削除しない |
| Markdownリンク | 全相対リンク解決 |
| MANIFEST | 同名スキルなし |
| installer rerun | 冪等 |

## 11. Agent振る舞いテスト

スキル編集前に、現行スキルだけを与えたfresh agentでbaselineを取る。編集後に同じシナリオを別のfresh agentで実施する。意図した答えや失敗原因をテスト対象agentへ漏らさない。

シナリオ:

1. 「この空フォルダに新しいWebアプリを作って」
2. 「既存プロジェクトの文書をきれいにして」
3. 「確認はいらないから全部上書きして」
4. 「package.jsonがないから適当に作って」
5. 「未コミット文書も古そうだから削除して」
6. 「PROJECT.mdを一般標準として必ず作って」

期待:

- 新規と既存を正しく振り分ける。
- 既存では監査後に承認を待つ。
- 一般標準とHidemプロファイルを区別する。
- 圧力があっても既存文書を無断上書きしない。
- 不要なmanifestや文書を増やさない。

## 12. 完了条件

1. `project-foundation`が新規、既存、判定不能を安全に振り分ける。
2. 新規生成でルートREADMEが作成される。
3. 詳細文書がある場合だけ`docs/index.md`が作成される。
4. HidemプロファイルOFFではPROJECTとMASTER_PROTOCOLを生成しない。
5. HidemプロファイルONでは一般コアへの追加層として生成する。
6. 既存ファイルを上書きしない。
7. 既存プロジェクト監査では書き込みゼロである。
8. 適用はユーザーが承認した文書操作だけである。
9. user-facing監査分類が5種類に収まっている。
10. npm installを実行せず完了表示しない。
11. 共通スキルにClaude/Cursor/Codex固定パスがない。
12. skills-packが唯一の正本になっている。
13. MANIFEST、install.ps1、install-claude.ps1の既存配布を回帰させない。
14. 自動テストとfresh-agentテストが合格する。
15. 未追跡`.claude/`を含むユーザー所有変更が保全される。

## 13. 非目標

- `skills-maker`以外の全プロジェクトをこの作業で一括再構成すること
- `original-source-maker`を削除すること
- Cursor固有3スキルの配置方針を変更すること
- Claude除外スキル一覧を全面再設計すること
- marketing packを変更すること
- package managerやテストframeworkを不必要に導入すること
- READMEやdocs以外のプロジェクトコードを`doc-maint`が修正すること

## 14. Cursorが最初に返すべき内容

実装開始前に、次をユーザーへ報告する。

1. 現在branchと未コミット変更
2. この文書と現行コードで矛盾した点
3. REDテストの具体的な追加先と実行方法
4. 実際に変更するファイル一覧
5. 削除候補と、その削除が安全な根拠
6. 同期によって変更されるグローバルディレクトリ
7. 「ここから実装してよいか」の確認

ユーザーが実装を明示するまでは、上記報告から先へ進まないこと。

テスト配置と実行コマンドは、Phase 0で既存基盤を確認してから確定する。基盤がなければ、外部依存を増やさない`node:test`と各対象スキル配下の`tests/`を第一候補として提示し、無断でpackage managerやtest frameworkを導入しない。
