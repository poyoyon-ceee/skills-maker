# skills-maker 設置マニュアル

Cursor Agent Skills を複数 PC で共有・配布するためのリポジトリです。

スキルは **1個ずつ入れる必要はありません**。`.cursor/skills/` 以下にカテゴリフォルダで並べると、Cursor が再帰的に `SKILL.md` を自動検出します。

## リポジトリ構成

```
skills-maker/
├── SETUP.md                              # このファイル（設置手順）
├── scripts/
│   ├── install-global.ps1                # Windows: グローバル一括インストール
│   └── install-global.sh                 # macOS/Linux: グローバル一括インストール
└── .cursor/skills/                       # スキル本体（公式パス）
    ├── debug/
    │   └── debug-allrun/
    │       └── SKILL.md
    └── github/
        └── github-make-sync/
            └── SKILL.md
```

## Cursor がスキルを読む場所

| 場所 | スコープ |
|------|----------|
| `.cursor/skills/` | プロジェクト単位（このリポジトリを開くだけで有効） |
| `~/.cursor/skills/` | グローバル（全プロジェクトで有効） |

**注意:** `~/.cursor/skills-cursor/` は Cursor 組み込み用。触らない。

## フォルダの組み方（まとめて入れる）

Cursor はスキルルートを**再帰的に走査**します。カテゴリフォルダは分類用で、スキル名は `SKILL.md` を直接含むフォルダ名になります。

```text
.cursor/skills/
├── github/
│   └── github-make-sync/
│       └── SKILL.md
├── deploy/
│   ├── staging/
│   │   └── SKILL.md
│   └── production/
│       └── SKILL.md
└── workflow/
    └── tdd/
        └── SKILL.md
```

上の例ではスキル名は `github-make-sync`、`staging`、`production`、`tdd` です（親の `github` や `deploy` はカテゴリ名のみ）。

新しいスキルを追加するときは `.cursor/skills/<カテゴリ>/<skill-name>/SKILL.md` を増やすだけで OK。

## 設置方法（3パターン）

### パターン A: このリポジトリだけで使う（最も簡単）

```powershell
git clone https://github.com/poyoyon-ceee/skills-maker.git
cd skills-maker
```

Cursor で `skills-maker` フォルダを開く。`.cursor/skills/` が自動読み込みされるため、**コピー不要**。

### パターン B: 全プロジェクトで使う（グローバル一括インストール）

`~/.cursor/skills/` にツリーごとコピーする。カテゴリフォルダ込みでまとめて入る。

#### Windows（PowerShell）

```powershell
cd C:\path\to\skills-maker
.\scripts\install-global.ps1
```

または手動:

```powershell
$dst = "$env:USERPROFILE\.cursor\skills"
New-Item -ItemType Directory -Force -Path $dst
Copy-Item -Path ".\.cursor\skills\*" -Destination $dst -Recurse -Force
```

#### macOS / Linux

```bash
cd /path/to/skills-maker
chmod +x scripts/install-global.sh
./scripts/install-global.sh
```

または手動:

```bash
mkdir -p ~/.cursor/skills
cp -r .cursor/skills/* ~/.cursor/skills/
```

### パターン C: GitHub から取り込む

Cursor の **Customize → Rules → Add Rule → Remote Rule (Github)** でこのリポジトリ URL を指定する方法もある（[公式ドキュメント](https://cursor.com/docs/skills)）。

### 参考: 外部スキル集の一括インストール

```bash
npx skills add <owner/repo> --all --global --yes
```

[skills.sh](https://skills.sh) 系の CLI。自分用リポを配布する場合はパターン A / B が素直。

## 前提条件

| 項目 | 内容 |
|------|------|
| Cursor | インストール済みであること |
| GitHub CLI (`gh`) | `github-make-sync` 利用時に必要 |
| Git | リポジトリの clone に必要 |

`gh` の確認:

```powershell
gh --version
gh auth status
```

未ログインの場合:

```powershell
gh auth login
```

## 初回設置（別 PC）手順まとめ

1. リポジトリを clone
2. 使い方に応じてパターン A または B を選択
3. Cursor を再起動（スキル一覧に出ない場合）
4. チャットで `/skill-name` または `@skill-name` で起動

```powershell
git clone https://github.com/poyoyon-ceee/skills-maker.git
cd skills-maker
```

## 配置確認

| 用途 | パス例 |
|------|--------|
| プロジェクトスキル | `skills-maker/.cursor/skills/github/github-make-sync/SKILL.md` |
| グローバルスキル (Windows) | `C:\Users\<ユーザー名>\.cursor\skills\github\github-make-sync\SKILL.md` |
| グローバルスキル (macOS/Linux) | `~/.cursor/skills/github/github-make-sync/SKILL.md` |

## スキル一覧

### github-make-sync

GitHub にプライベートリポジトリを作成し、現在開いているプロジェクトと `origin` を連携する。

**起動方法:**

- `/github-make-sync`
- `@github-make-sync`（スキル一覧から選択）

**動作:**

1. リポジトリ名を質問
2. GitHub に private リポを作成
3. カレントプロジェクトに `remote origin` を設定
4. コミットがあれば push（なければ連携のみ）

## スキル更新時

### パターン A（プロジェクトスキルのみ）

```powershell
cd skills-maker
git pull
```

Cursor を開き直す（必要なら）。

### パターン B（グローバル）

```powershell
cd C:\path\to\skills-maker
git pull
.\scripts\install-global.ps1
```

macOS / Linux:

```bash
cd /path/to/skills-maker
git pull
./scripts/install-global.sh
```

## 新しいスキルを追加するとき

1. `.cursor/skills/<カテゴリ>/<skill-name>/SKILL.md` を追加
2. このリポジトリに commit / push
3. 各 PC で `git pull` → パターン B なら `install-global` を再実行

## 方式の比較

| 方式 | メリット | デメリット |
|------|----------|------------|
| パターン A（プロジェクト） | clone するだけ | 他プロジェクトでは使えない |
| パターン B（グローバルコピー） | 全プロジェクトで使える | 更新時に再コピーが必要 |
| シンボリックリンク | pull だけで更新 | Windows で再起動後に消える報告あり |

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| スキルが一覧に出ない | Cursor 再起動、パスを確認 |
| `gh: command not found` | [GitHub CLI](https://cli.github.com/) をインストール |
| リポ作成に失敗 | `gh auth login` で再認証 |
| 同名リポが既にある | 別のリポジトリ名を指定 |
| シンボリックリンクが消える | コピー方式（パターン B）を使う |

## 補足: シンボリックリンク（上級者向け）

コピーの代わりにリンクして常に同期することもできるが、Windows では再起動後に検出されない報告がある。**推奨は `install-global` によるコピー。**

#### Windows（ジャンクション）

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.cursor\skills\github"
cmd /c mklink /J "$env:USERPROFILE\.cursor\skills\github\github-make-sync" "C:\path\to\skills-maker\.cursor\skills\github\github-make-sync"
```

#### macOS / Linux

```bash
mkdir -p ~/.cursor/skills/github
ln -sf /path/to/skills-maker/.cursor/skills/github/github-make-sync ~/.cursor/skills/github/github-make-sync
```
