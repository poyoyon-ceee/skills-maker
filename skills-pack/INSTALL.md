# 別PC向け：グローバルスキル一括インストール

**コードがわからなくてもOK → [引き継ぎ.md](引き継ぎ.md) を開き、コピペ用の一言を Cursor エージェントに送るだけ。**

この `skills-pack/` フォルダだけで、別PCの Cursor にグローバルスキルを入れられます。

## このフォルダの中身

| 種類 | 場所 | インストール先 |
|------|------|----------------|
| スキル本体（98個） | 各カテゴリフォルダ | `~/.cursor/skills/` |
| スキル一覧 | `MANIFEST.json` | （参照用） |
| セッションフック | `_hooks/` | `~/.cursor/hooks/` |
| インストーラ | `install.ps1` / `install.sh` | （実行するだけ） |
| Claude Code 用差分 | `_claude/` | `~/.claude/skills/`（`install-claude.ps1` 経由） |
| Claude Code 用インストーラ | `install-claude.ps1` | （実行するだけ） |

`_hooks/`・`_claude/`・`install.*` はスキルではない。インストール時に Cursor のスキルフォルダへはコピーされない。

## Claude Code 向けインストール

```powershell
cd C:\path\to\skills-maker\skills-pack
.\install-claude.ps1
```

Cursor 版との違い:

- インストール先は `~/.claude/skills/`。カテゴリフォルダ（marketingskills/ 等）は剥がして `~/.claude/skills/<スキル名>/` に平置きされる
- **除外10スキル**（Claude Code の組み込み機能と重複するため入れない・既存なら削除）:
  `docx`, `pdf`, `pptx`, `xlsx`, `skill-creator`（公式スキルと重複）,
  `using-superpowers`, `requesting-code-review`, `receiving-code-review`,
  `verification-before-completion`, `using-git-worktrees`（組み込みの /code-review・/verify・worktree 機能と重複）
- **`_claude/` オーバーレイ**: ベースコピー後、`_claude/<スキル名>/` のファイルで上書きする。Cursor 固有の記述（`~/.cursor/skills/` パス、Cursor browser MCP、Cursor User Rules 参照）を Claude Code 向けに直した差し替え版。現在 `new-project` / `webapp-testing` / `writing-plans` の3つ
- Cursor 用フック（`_hooks/`）は入れない（Claude Code のフック形式は別物）

**今後の運用ルール**: 新スキルは原則プラットフォーム中立に書く（IDE 名・IDE 固有パスを書かない）。どうしても IDE 固有の手順が必要な場合のみ `_claude/<スキル名>/` に Claude 版の差し替えファイルを置く。

## 重複の扱い（別PCに既存スキルがある場合）

`install.ps1` / `install.sh` は次を自動で行う:

1. **同名・同内容** → スキップ（二重インストールしない）
2. **同名・別パス・別内容** → skills-pack のパスを正本として残し、重複パスを削除
3. **旧ネスト構造**（例: `writing-plans/writing-plans/`）→ 既知パターンを削除
4. **skills-pack に無い別スキル** → 触らない（devils / persona など）

まだ重複が残る場合は [skills重複処理.md](skills重複処理.md) をエージェントに実行させる。

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
4. 同名スキルが2件出ない

## 含まれるスキル（98個・概要）

| カテゴリ | 例 |
|----------|-----|
| playbooks（7） | `playbook-document-data`, `playbook-mini-webapp` |
| marketingskills（46） | `copywriting`, `seo-audit`, `launch` |
| superpowers（12） | `brainstorming`, `systematic-debugging` |
| Anthropic（8） | `pdf`, `docx`, `xlsx`, `pptx`, `skill-creator` |
| Matt Pocock | `to-prd`, `to-issues`, `edit-article` など |
| Obsidian（3） | `obsidian-vault`, `obsidian-markdown`, `json-canvas` |
| 3rd party | `notebooklm`, `react-best-practices` など |
| GWS（3） | `gws-docs`, `gws-sheets`, `gws-drive` |
| 独自（残り） | `grill-me`, `writing-plans`, `webapp-testing`, `new-project` など |

全件は [MANIFEST.json](MANIFEST.json) を参照。

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| スキルが出ない | Cursor 再起動 |
| 同名スキルが2つ（例: `/writing-plans`） | Superpowers プラグインと skills-pack が共存、または Cursor が `~/.claude/skills` も読んでいる。Settings → Rules, Skills, Subagents → **Include Third-Party...** を OFF → 残れば [skills重複処理.md](skills重複処理.md) |
| フックが出ない | `~/.cursor/hooks/session-start.ps1`（Windows）があるか確認 |
| GWS が動かない | `gws auth login` を別途実行（OAuth は PC ごと） |

## リポジトリ全体の説明

上位の [SETUP.md](../SETUP.md) と [skills一覧.md](../skills一覧.md) も参照。
