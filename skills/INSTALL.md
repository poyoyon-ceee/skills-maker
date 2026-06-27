# 別PC向け：グローバルスキル一括インストール

**コードがわからなくてもOK → [引き継ぎ.md](引き継ぎ.md) を開き、コピペ用の一言を Cursor エージェントに送るだけ。**

この `skills/` フォルダだけで、別PCの Cursor にグローバルスキルを入れられます。

## このフォルダの中身

| 種類 | 場所 | インストール先 |
|------|------|----------------|
| スキル本体（19個） | `debug/`, `github/`, `grill-me/`, `superpowers/`, など | `~/.cursor/skills/` |
| セッションフック | `_hooks/` | `~/.cursor/hooks/` |
| インストーラ | `install.ps1` / `install.sh` | （実行するだけ） |

`_hooks/` と `install.*` はスキルではない。インストール時に Cursor のスキルフォルダへはコピーされない。

## 前提

- Cursor がインストール済み
- `skills-maker` リポジトリを clone 済み（またはこのフォルダがあること）
- `github-make-sync` を使う場合のみ [GitHub CLI](https://cli.github.com/) + `gh auth login`

## 初回（Windows）

```powershell
cd C:\path\to\skills-maker\skills
.\install.ps1
```

## 初回（macOS / Linux）

```bash
cd /path/to/skills-maker/skills
chmod +x install.sh
./install.sh
```

## 更新時

```powershell
cd C:\path\to\skills-maker
git pull
cd skills
.\install.ps1
```

## インストール後の確認

1. **Cursor を再起動**
2. **Customize → Skills** — `/brainstorming`, `/writing-plans`, `/github-make-sync` などが見える
3. **Customize → Hooks** — `session-start` が登録されている

## 含まれるスキル（19個）

**独自（7）**
- `debug-allrun`, `github-make-sync`, `git-in-clone`, `grill-me`
- `test-driven-development`（ローカル改良版）
- `writing-plans`（ローカル Adapt 版）
- `webapp-testing`

**Superpowers（12）** — `superpowers/` 以下  
TDD と writing-plans は Superpowers 版ではなく、上記ローカル版を使用。

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| スキルが出ない | Cursor 再起動 |
| フックが出ない | `~/.cursor/hooks/session-start.ps1`（Windows）があるか確認 |
| 既存フックと競合 | `install.ps1` は `sessionStart` をマージする。他フックは手動確認 |

## リポジトリ全体の説明

上位の [SETUP.md](../SETUP.md) と [skills一覧.md](../skills一覧.md) も参照。
