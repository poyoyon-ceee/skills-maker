# 別PC向け：グローバルスキル一括インストール

**コードがわからなくてもOK → [引き継ぎ.md](引き継ぎ.md) を開き、コピペ用の一言を Cursor エージェントに送るだけ。**

この `skills-pack/` フォルダだけで、別PCにグローバルスキルを入れられます。

## インストール先の構成（重要）

**1スキル＝1箇所。同じスキルを2つの root に置かない。**

| root | 中身 | 読むツール |
|------|------|-----------|
| `~/.agents/skills/<スキル名>/` | 通常のスキル（53件・平置き） | Cursor / Codex / ChatGPT 系 |
| `~/.cursor/skills/<スキル名>/` | Cursor 固有スキル（3件） | Cursor のみ |
| `~/.cursor/hooks/` | セッションフック | Cursor のみ |
| `~/.claude/skills/<スキル名>/` | Claude Code 用（`install-claude.ps1`・除外10で46件） | Claude Code のみ |

Cursor 固有の3件は `chat-handoff` / `skill-creator` / `promote-skill`。`install.ps1` では `~/.cursor/skills/` のみに置く（共有の `~/.agents` には置かない）。ただし **`promote-skill` の手順自体は Claude Code でも使う**（`install-claude.ps1` で `~/.claude` にも入り、Gate 1 宛先に `~/.claude/skills/` を選べる）。`chat-handoff` / `skill-creator` は従来どおり Cursor 前提。

**重複の禁止範囲:** ダメなのは同名を `~/.agents` と `~/.cursor` の両方に置くこと。`~/.agents` と `~/.claude` の併置は可（別ツールが読む）。

**平置きにする理由**: pack 内のカテゴリフォルダ（`playbooks/` `superpowers/` `github/` `debug/`）は整理用。Codex がネストしたスキルディレクトリを辿る保証がないため、インストール時に剥がして `<スキル名>/SKILL.md` にする。

**`~/.agents` を主にする理由**: Cursor の設定 **Include Third-Party Plugins, Skills, and Other Configs** を OFF にしても `~/.agents/skills` は読まれる（あのトグルの対象は `~/.claude` 等のよそのベンダー設定）。ChatGPT / Codex とも共有できるので、ここを正本にすれば重複が起きない。

## このフォルダの中身

| 種類 | 場所 | インストール先 |
|------|------|----------------|
| スキル本体（56個） | 各カテゴリフォルダ | `~/.agents/skills/`（53） / `~/.cursor/skills/`（3） |
| スキル一覧 | `MANIFEST.json` | （参照用。`installTarget` に宛先が入っている） |
| セッションフック | `_hooks/` | `~/.cursor/hooks/` |
| インストーラ | `install.ps1` / `install.sh` | （実行するだけ） |
| Claude Code 用差分 | `_claude/` | `~/.claude/skills/`（`install-claude.ps1` 経由） |
| Claude Code 用インストーラ | `install-claude.ps1` | （実行するだけ） |

`_hooks/`・`_claude/`・`install.*` はスキルではない。インストール時にスキルフォルダへはコピーされない。

## Claude Code 向けインストール

```powershell
cd C:\path\to\skills-maker\skills-pack
.\install-claude.ps1
```

`install.ps1` との違い:

- インストール先は **`~/.claude/skills/` のみ**。`~/.agents/skills/` は `install.ps1` が管理するので、こちらからは書かない
- **除外10スキル**（Claude Code の組み込み機能と重複するため入れない・既存なら削除）:
  `docx`, `pdf`, `pptx`, `xlsx`, `skill-creator`（公式スキルと重複）,
  `using-superpowers`, `requesting-code-review`, `receiving-code-review`,
  `verification-before-completion`, `using-git-worktrees`（組み込みの /code-review・/verify・worktree 機能と重複）
- **`_claude/` オーバーレイ**: ベースコピー後、`_claude/<スキル名>/` のファイルで上書きする。Cursor 固有の記述（`~/.cursor/skills/` パス、Cursor browser MCP、Cursor User Rules 参照）を Claude Code 向けに直した差し替え版。現在 `new-project` / `webapp-testing` / `writing-plans` の3つ
- Cursor 用フック（`_hooks/`）は入れない（Claude Code のフック形式は別物）

**今後の運用ルール**: 新スキルは原則プラットフォーム中立に書く（IDE 名・IDE 固有パスを書かない）。どうしても IDE 固有の手順が必要な場合のみ `_claude/<スキル名>/` に Claude 版の差し替えファイルを置く。

## 重複の扱い（別PCに既存スキルがある場合）

`install.ps1` / `install.sh` は次を自動で行う:

1. **同名・同内容** → 書き込まない（ハッシュ比較でスキップ）
2. **`~/.cursor/skills/` に残った移行前のスキル** → `~/.cursor/skills.bak/` へ退避（削除はしない）
3. **Cursor 固有3件が `~/.agents/skills/` にある** → 削除（正しい root は `~/.cursor`）
4. **pack 内に同名スキルが2つ** → エラーで中断（壊れた状態を配らない）
5. **skills-pack に無い別スキル** → 触らない（devils / persona など）

最後に全 root を走査して同名が2件以上ないことを検証し、残っていれば WARNING を出す。まだ重複が残る場合は [skills重複処理.md](skills重複処理.md) をエージェントに実行させる。

## 注意（別PC向け）

- **GWS OAuth（`gws auth login`）は PC ごと。** skills-pack には OAuth 設定は入らない。Google Docs / Sheets / Drive を使う場合は、別 PC でも `gws` CLI のインストールと OAuth セットアップが必要。
- **別 PC に Superpowers プラグインが入っていると重複の可能性あり。** `install.ps1` 実行後、Customize → Skills で `/writing-plans` などが **2件** 出たら [skills重複処理.md](skills重複処理.md) を実行。`/add-plugin superpowers` は使わないこと。

## 前提

- Cursor がインストール済み
- `skills-maker` リポジトリを clone 済み（またはこのフォルダがあること）
- `github-make-sync` を使う場合のみ [GitHub CLI](https://cli.github.com/) + `gh auth login`
- `playbook-document-data` の Google 連携を使う場合のみ `gws` CLI + OAuth（別途セットアップ）

## 初回（Windows）

```powershell
cd C:\path\to\skills-maker\skills-pack
.\install.ps1
```

## 初回（macOS / Linux）

```bash
cd /path/to/skills-maker/skills-pack
chmod +x install.sh
./install.sh
```

## 更新時

```powershell
cd C:\path\to\skills-maker
git pull
cd skills-pack
.\install.ps1
```

## インストール後の確認

1. **Cursor を再起動**
2. **Customize → Skills** — `/playbook-document-data`, `/gws-docs`, `/brainstorming` などが見える
3. **Customize → Hooks** — `session-start` が登録されている
4. **同名スキルが2件出ない** — 設定画面の件数と `/` メニューの件数が一致すること（ズレていたら重複が残っている）

## 含まれるスキル（56個・概要）

**マーケ系は含まない。** LP・広告・訴求スキルは別パック [skills-pack-marketing](../skills-pack-marketing/INSTALL.md)（オプトイン）。通常の本 install では入らない・戻らない。

| カテゴリ | 例 |
|----------|-----|
| playbooks（7） | `route-playbook`（入口ルーター）, `playbook-document-data`, `playbook-mini-webapp` 等（`playbook-lp-creative` は marketing パック）。各 playbook は Adaptive proposal gate 付き |
| superpowers（12） | `brainstorming`, `systematic-debugging` |
| Anthropic系（5） | `pdf`, `docx`, `xlsx`, `pptx`, `skill-creator` |
| デザイン系 | `theme-factory`, `canvas-design`, `frontend-design`, `doc-coauthoring` など |
| Matt Pocock | `to-prd`, `to-issues`, `edit-article` など |
| Obsidian（3） | `obsidian-vault`, `obsidian-markdown`, `json-canvas` |
| 3rd party | `notebooklm`, `react-best-practices` など |
| GWS（3） | `gws-docs`, `gws-sheets`, `gws-drive` |
| Cursor 固有（3） | `chat-handoff`, `skill-creator`, `promote-skill`（`~/.cursor/skills/` のみ） |
| 独自（残り） | `grill-me`, `writing-plans`, `webapp-testing`, `new-project`, `doc-maint` など |

全件は [MANIFEST.json](MANIFEST.json) を参照。

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| スキルが出ない | Cursor 再起動 |
| 設定画面と `/` メニューで件数が違う | 同名スキルが複数 root にある。設定画面は名前で重複排除するが `/` メニューはしないため件数がズレる。[skills重複処理.md](skills重複処理.md) |
| 同名スキルが2つ（例: `/writing-plans`） | `~/.agents/skills` と `~/.cursor/skills` の両方にある、または Superpowers プラグインと共存。`install.ps1` 再実行で自動退避 → 残れば [skills重複処理.md](skills重複処理.md) |
| `~/.agents` のスキルを編集しても反映されない | 同名が `~/.cursor/skills` にもあり、そちらが読まれている可能性。片方に寄せる |
| フックが出ない | `~/.cursor/hooks/session-start.ps1`（Windows）があるか確認 |
| Office スキル（docx/xlsx/pptx）が動かない | Python ライブラリ不足。`pip install python-docx openpyxl python-pptx` |
| GWS が動かない | `gws auth login` を別途実行（OAuth は PC ごと） |

## リポジトリ全体の説明

上位の [SETUP.md](../SETUP.md) と [skills一覧.md](../skills一覧.md) も参照。
