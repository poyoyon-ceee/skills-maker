# skills-maker 設置マニュアル

Cursor Agent Skills を複数 PC で共有・配布するためのリポジトリです。

**運用方針: スキルはすべてグローバルに置く。通常は `~/.agents/skills/`、Cursor 固有のものだけ `~/.cursor/skills/`。**  
各プロジェクトの `.cursor/skills/` には置かない。このリポジトリの `skills-pack/` が配布用の正本。**同じスキルを2つの root に置かない**（重複表示の原因）。

## リポジトリ構成

```
skills-maker/
├── SETUP.md
├── skills一覧.md
├── スキルの使いどころ.md
├── scripts/
│   ├── install-global.ps1
│   ├── install-global.sh
│   ├── install-hooks.ps1
│   └── install-hooks.sh
├── hooks/
│   ├── session-start.ps1       # Windows: Superpowers セッションフック
│   ├── session-start           # macOS/Linux
│   └── hooks.json.example
├── skills-pack/               # 日常用配布（スキル + インストーラ + 別PC手順）
│   ├── INSTALL.md
│   ├── 引き継ぎ.md
│   ├── MANIFEST.json          # 55スキル一覧（name / path / installTarget）
│   ├── install.ps1 / install.sh
│   ├── install-claude.ps1
│   ├── _hooks/
│   └── …（marketingskills なし）
└── skills-pack-marketing/     # マーケ用オプトイン（通常 install では入らない）
    ├── INSTALL.md
    ├── 引き継ぎ.md
    ├── MANIFEST.json          # 47件（marketingskills 46 + playbook-lp-creative）
    ├── install.ps1 / install.sh
    ├── marketingskills/
    └── playbooks/playbook-lp-creative/
```

## エージェントがスキルを読む場所

| 場所 | 読むツール | このリポの方針 |
|------|-----------|----------------|
| `~/.agents/skills/` | Cursor / Codex / ChatGPT 系 | **通常はここ（52件）** |
| `~/.cursor/skills/` | Cursor のみ | Cursor 固有の3件だけ |
| `~/.claude/skills/` | Claude Code | `install-claude.ps1` の管轄 |
| `.cursor/skills/`（プロジェクト内） | Cursor のみ | **使わない** |

**注意:** `~/.cursor/skills-cursor/` は Cursor 組み込み用。触らない。

Cursor 固有の3件は `chat-handoff` / `skill-creator` / `promote-skill`。`~/.cursor` パス・Cursor UI・Cursor 用 PowerShell を前提にしているため共有 root に置かない。

**Include Third-Party トグルは `~/.agents` に効かない。** OFF にしても読まれ続ける（`~/.agents/` は `AGENTS.md` と同じベンダー中立の標準パスで、Cursor はネイティブな探索先として扱うため）。

## フォルダの組み方

**インストール先は平置き。** カテゴリフォルダは `skills-pack/` 内の整理用で、インストール時に剥がされる。Codex がネストしたスキルディレクトリを辿る保証がないため。

```text
skills-pack/                      →  ~/.agents/skills/
├── github/                          ├── github-make-sync/
│   └── github-make-sync/            │   └── SKILL.md
│       └── SKILL.md                 ├── debug-allrun/
├── debug/                           │   └── SKILL.md
│   └── debug-allrun/                └── writing-plans/
│       └── SKILL.md                     └── SKILL.md
└── writing-plans/
    └── SKILL.md                  →  ~/.cursor/skills/
                                     ├── chat-handoff/
                                     ├── skill-creator/
                                     └── promote-skill/
```

新しいスキルは `/promote-skill` で追加する（宛先の判断と MANIFEST 更新まで含む2段確認フロー）。

## 初回設置（別 PC）

**コード不要。** `skills-pack/引き継ぎ.md` をエージェントに見せて、書いてある「コピペ用の一言」を送るだけ。

自分でやる場合のみ:

```powershell
cd C:\path\to\skills-maker\skills-pack
.\install.ps1
```

Cursor を再起動し、Customize → Skills で一覧を確認。

## スキル更新時

```powershell
cd C:\path\to\skills-maker
git pull
cd skills-pack
.\install.ps1
```

## Superpowers との重複整理

[obra/superpowers](https://github.com/obra/superpowers) と同名スキルがある場合、**より精度の高い版を1つだけ残す**。

| スキル | 採用版 | 理由 |
|--------|--------|------|
| `test-driven-development` | ローカル改良版 | Superpowers 本体 + マルチスタックテストコマンド表。プラグインで上書きしない |
| `writing-plans` | ローカル Adapt 版 | `docs/plans/`、日本語アナウンス、コミットはユーザー指示時のみ |

Superpowers を丸ごと `/add-plugin` する場合は、上記2つは**重複インストールしない**こと。

### Superpowers の導入（TDD / writing-plans 除外）

`skills-pack/install.ps1` がスキル一式 + セッションフックをインストールする。`skills-pack/superpowers/` 以下に12スキル。`test-driven-development` と `writing-plans` は同梱のローカル版を使用（Superpowers プラグイン版で上書きしない）。

### Superpowers セッションフック（プラグイン代替）

`/add-plugin superpowers` は使わない。`skills-pack/_hooks/` のフックを `install.ps1` が `~/.cursor/hooks/` へ配置する。

## 新しいスキルを追加するとき

**`/promote-skill` を使う**（2段確認: global に入れる？ → skills-pack に同期する？）。宛先の判断・重複チェック・MANIFEST 更新まで含む。

手動でやる場合:

1. `skills-pack/<カテゴリ>/<skill-name>/SKILL.md` を追加
2. `.\scripts\generate-manifest.ps1` で MANIFEST を再生成
3. `cd skills-pack; .\install.ps1` でこの PC に反映
4. commit / push
5. 他 PC で `git pull` → `skills-pack/install.ps1`

同名スキルが既にある場合は両方の `SKILL.md` を比較し、精度の高い方だけ残す。**両方の root に置かない。**

### 保守用スクリプト

| スクリプト | 用途 |
|-----------|------|
| `scripts/generate-manifest.ps1` | `skills-pack/MANIFEST.json` を再生成（pack 内の同名重複を検出して中断） |
| `scripts/check-pack-drift.ps1` | pack とインストール済みグローバルの差分を表示（読み取り専用） |
| `scripts/sync-skills-pack.ps1` | グローバル → pack へ逆同期（`-WhatIf` でドライラン） |

## 前提条件

| 項目 | 内容 |
|------|------|
| Cursor | インストール済み |
| GitHub CLI (`gh`) | `github-make-sync` 利用時 |
| Git | clone / pull に必要 |

## 配置確認

| OS | パス例 |
|----|--------|
| Windows | `C:\Users\<ユーザー名>\.agents\skills\github-make-sync\SKILL.md` |
| macOS/Linux | `~/.agents/skills/github-make-sync/SKILL.md` |
| Cursor 固有（Windows） | `C:\Users\<ユーザー名>\.cursor\skills\promote-skill\SKILL.md` |

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| スキルが一覧に出ない | Cursor 再起動、`~/.agents/skills/` を確認 |
| 設定画面と `/` メニューで件数が違う | 同名スキルが複数 root にある。設定画面は重複排除するが `/` メニューはしない → [skills-pack/skills重複処理.md](skills-pack/skills重複処理.md) |
| 同名スキルが2つ出る | `~/.agents` と `~/.cursor` の両方にある、または Superpowers プラグインと重複。`skills-pack/install.ps1` 再実行で自動退避 |
| 編集しても反映されない | 同名が別 root にもあり、そちらが読まれている。片方に寄せる |
| `gh: command not found` | [GitHub CLI](https://cli.github.com/) をインストール |
| フックが動かない | Customize → Hooks を確認。`~/.agents/skills/using-superpowers/SKILL.md` があるか確認 |
| Office スキルが動かない | `pip install python-docx openpyxl python-pptx` |

## 参考

- スキル一覧: [skills一覧.md](skills一覧.md)
- 使い分け: [スキルの使いどころ.md](スキルの使いどころ.md)
- Cursor 公式: [Agent Skills](https://cursor.com/docs/skills)
