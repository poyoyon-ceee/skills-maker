# 別PC向け：グローバルスキル一括インストール

**コードがわからなくてもOK → [引き継ぎ.md](引き継ぎ.md) を開き、コピペ用の一言を Cursor エージェントに送るだけ。**

この `skills-pack/` フォルダだけで、別PCの Cursor にグローバルスキルを入れられます。

## このフォルダの中身

| 種類 | 場所 | インストール先 |
|------|------|----------------|
| スキル本体（94個） | 各カテゴリフォルダ | `~/.cursor/skills/` |
| スキル一覧 | `MANIFEST.json` | （参照用） |
| セッションフック | `_hooks/` | `~/.cursor/hooks/` |
| インストーラ | `install.ps1` / `install.sh` | （実行するだけ） |

`_hooks/` と `install.*` はスキルではない。インストール時に Cursor のスキルフォルダへはコピーされない。

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

## 含まれるスキル（94個・概要）

| カテゴリ | 例 |
|----------|-----|
| playbooks（7） | `playbook-document-data`, `playbook-mini-webapp` |
| marketingskills（46） | `copywriting`, `seo-audit`, `launch` |
| superpowers（12） | `brainstorming`, `systematic-debugging` |
| Anthropic（8） | `pdf`, `docx`, `xlsx`, `pptx`, `skill-creator` |
| Matt Pocock（5） | `to-prd`, `obsidian-vault` |
| 3rd party（4） | `notebooklm`, `react-best-practices` |
| GWS（3） | `gws-docs`, `gws-sheets`, `gws-drive` |
| 独自（残り） | `grill-me`, `writing-plans`, `webapp-testing` など |

全件は [MANIFEST.json](MANIFEST.json) を参照。

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| スキルが出ない | Cursor 再起動 |
| 同名スキルが2つ（例: `/writing-plans`） | Superpowers プラグインと skills-pack が共存している可能性。`install.ps1` 再実行 → 残れば [skills重複処理.md](skills重複処理.md) |
| フックが出ない | `~/.cursor/hooks/session-start.ps1`（Windows）があるか確認 |
| GWS が動かない | `gws auth login` を別途実行（OAuth は PC ごと） |

## リポジトリ全体の説明

上位の [SETUP.md](../SETUP.md) と [skills一覧.md](../skills一覧.md) も参照。
