# 新規スキル受付ルール（正本）

手順の全文はこのファイルだけ。他の SETUP / INSTALL / 一覧 / カタログ README には短いリンクのみ書く。

## 置き場所（4箱だけ）

新規スキルは次の **4箱のどれか1つ** にフォルダごと置く。**日本語名の箱は作らない。**

| 箱 | installTargets |
|---|---|
| incoming/agents-claude/ | ["agents", "claude"] |
| incoming/agents-only/ | ["agents"] |
| incoming/claude-only/ | ["claude"] |
| incoming/cursor-only/ | ["cursor"] |

### フォルダ名と `name`

- **inbox のフォルダ名** は、その中の `SKILL.md` frontmatter の **`name` と完全一致** させる。
- 一致しないスキルは **同期しない**（inbox に残す）。

### トークンの意味（順序: agents → cursor → claude）

| トークン | 実パス | 読むツール |
|---------|--------|-----------|
| `agents` | `~/.agents/skills/` | **Cursor・Codex・ChatGPT 系**（GPT 専用ではない） |
| `cursor` | `~/.cursor/skills/` | Cursor のみ |
| `claude` | `~/.claude/skills/` | Claude Code のみ |

- **`agents` と `cursor` を同じ `installTargets` に並べない**（同期スクリプトが拒否する）。
- `~/.agents/skills` と `~/.cursor/skills` に **同名スキルを両方置かない**。

### 箱を増やさない例外

`chat-handoff` と `promote-skill` は既存どおり **`["cursor", "claude"]`**（専用箱は作らない）。通常の新規スキルは上表の4箱で選ぶ。

## 登録（同期）のやり方

1. ユーザーが **「同期して」** など同期を依頼したら、**手で `~/.agents` / `~/.cursor` / `skills-pack` へコピーしない**。
2. リポジトリルートで **このスクリプトだけ** 実行する:

```powershell
cd C:\path\to\skills-maker
.\scripts\sync-incoming.ps1
```

（macOS/Linux も PowerShell 7 等で同じパス。`-SkipPdf` で PDF と Excel を省略可。一覧の md 更新は省略しない。）

スクリプトが行うこと（詳細は実装に従う）: inbox → `skills-pack/<name>/`、MANIFEST の `installTargets` 更新、`skills一覧.md` 行追加、グローバルへの平置きコピー、カタログ PDF と `skills一覧.xlsx` の再生成（`-SkipPdf` のとき除く）。

## 一覧に載せるための frontmatter

**inbox から同期するスキル**は、`SKILL.md` に次が **すべて** ないと **同期しない**。inbox に残し、エラーとして報告する。

- `catalog-section`（整数）
- `catalog-summary`
- `catalog-when`

`catalog-when` が `—` の行は一覧に作らない（PDF も捨てる）。

すでに `skills-pack` にあるスキルの説明・使いどころの正本は、リポジトリ直下の `skills一覧.md` である。catalog 3キーが無い既存スキルは、そのままで配布してよい。説明だけ変えるときは `skills一覧.md` を直し、`scripts/update-skills-catalog.ps1` で PDF（Excel も要るなら `-Excel`）を作り直す。inbox から既存スキルを上書き同期するときだけ、先に3キーを足す。

## エージェント向けチェックリスト

1. 4箱のどれに置くか決める（上表の `installTargets` に合わせる）。
2. フォルダ名 = `name`、必要な catalog 3キーを frontmatter に書く。
3. ユーザー確認後、`scripts/sync-incoming.ps1` を実行する。
4. 失敗したスキルは inbox に残る。成功分だけ pack / グローバル / 一覧が更新される。
5. **git commit / push はユーザーが明示したときだけ。**
