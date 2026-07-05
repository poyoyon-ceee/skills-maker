# skills-maker 設置マニュアル

Cursor Agent Skills を複数 PC で共有・配布するためのリポジトリです。

**運用方針: スキルはすべてグローバル（`~/.cursor/skills/`）に置く。**  
各プロジェクトの `.cursor/skills/` には置かない。このリポジトリの `skills/` が配布用の正本。

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
└── skills-pack/               # 配布パッケージ（スキル + インストーラ + 別PC手順）
    ├── INSTALL.md             # 別PC向け手順（ここを読む）
    ├── 引き継ぎ.md            # エージェントに渡す一言
    ├── MANIFEST.json          # 98スキル一覧
    ├── install.ps1            # Windows: 一括インストール（重複安全）
    ├── install.sh             # macOS/Linux
    ├── _hooks/                # セッションフック（スキルではない）
    ├── debug/
    ├── github/
    ├── grill-me/
    ├── superpowers/
    ├── test-driven-development/
    ├── webapp-testing/
    └── writing-plans/
```

## Cursor がスキルを読む場所

| 場所 | スコープ | このリポの方針 |
|------|----------|----------------|
| `~/.cursor/skills/` | グローバル（全プロジェクト） | **ここに置く** |
| `.cursor/skills/` | プロジェクト単位 | **使わない** |

**注意:** `~/.cursor/skills-cursor/` は Cursor 組み込み用。触らない。

## フォルダの組み方（まとめて入れる）

Cursor はスキルルートを**再帰的に走査**します。カテゴリフォルダは分類用で、スキル名は `SKILL.md` を直接含むフォルダ名になります。

```text
~/.cursor/skills/
├── github/
│   └── github-make-sync/
│       └── SKILL.md
├── debug/
│   └── debug-allrun/
│       └── SKILL.md
└── writing-plans/
    └── SKILL.md
```

新しいスキルを追加するときは `skills/<カテゴリ>/<skill-name>/SKILL.md` を増やし、`install-global` で各 PC に反映。

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

`skills/install.ps1` がスキル12個 + セッションフックを一括インストールする。

`skills/superpowers/` 以下に12スキル。`test-driven-development` と `writing-plans` は同梱のローカル版を使用。

### Superpowers セッションフック（プラグイン代替）

`/add-plugin superpowers` は使わない。`skills/_hooks/` のフックを `install.ps1` が `~/.cursor/hooks/` へ配置する。

## 新しいスキルを追加するとき

1. `skills/<カテゴリ>/<skill-name>/SKILL.md` を追加
2. この PC の `~/.cursor/skills/` にコピー（または `install-global` の逆同期）
3. commit / push
4. 他 PC で `git pull` → `skills/install.ps1`

同名スキルが既にある場合は両方の `SKILL.md` を比較し、精度の高い方だけ残す。

## 前提条件

| 項目 | 内容 |
|------|------|
| Cursor | インストール済み |
| GitHub CLI (`gh`) | `github-make-sync` 利用時 |
| Git | clone / pull に必要 |

## 配置確認

| OS | パス例 |
|----|--------|
| Windows | `C:\Users\<ユーザー名>\.cursor\skills\github\github-make-sync\SKILL.md` |
| macOS/Linux | `~/.cursor/skills/github/github-make-sync/SKILL.md` |

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| スキルが一覧に出ない | Cursor 再起動、`~/.cursor/skills/` を確認 |
| 同名スキルが2つ出る | Superpowers プラグインと手動コピーが重複。どちらか削除 |
| `gh: command not found` | [GitHub CLI](https://cli.github.com/) をインストール |
| フックが動かない | Customize → Hooks を確認。`~/.cursor/skills/superpowers/using-superpowers/SKILL.md` があるか確認 |

## 参考

- スキル一覧: [skills一覧.md](skills一覧.md)
- 使い分け: [スキルの使いどころ.md](スキルの使いどころ.md)
- Cursor 公式: [Agent Skills](https://cursor.com/docs/skills)
