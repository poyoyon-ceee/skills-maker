# Claude Code Superpowers 二重解消

日付: 2026-08-19  
状態: approved  
範囲: Approach A（`install-claude.ps1` にプラグイン無効化を内蔵。Cursor / Codex / `install.ps1` は不変）

## 問題

Claude Code は Superpowers を **2経路** で読んでいる。

1. プラグイン `superpowers@superpowers-marketplace`（`~/.claude/settings.json` の `enabledPlugins`）
2. `install-claude.ps1` がコピーした `~/.claude/skills/` 内の Superpowers スキル

プラグインは 14 スキルを持つ。`install-claude.ps1` が `.claude/skills` から外しているのはそのうち 4 つだけ（`using-superpowers` / `requesting-code-review` / `receiving-code-review` / `using-git-worktrees`）。残り 10 は二重。

Cursor 側はすでに「`/add-plugin superpowers` は使うな（TDD / writing-plans が上書きされる）」と決めている。Claude だけプラグイン ON ＋ pack コピーのハイブリッドになっており、方針が割れている。

`_claude/` オーバーレイは pack 側のカスタムを守るためのもの（`writing-plans` / `subagent-driven-development` / `systematic-debugging`）。プラグインを正本にするとこの差し替えは効かない。

ドキュメントの除外理由も不正確: `using-superpowers` は Claude 組み込みではなく、プラグイン由来。

## 目標

Claude Code の Superpowers 正本を **skills-pack** に一本化する。

- プラグインは無効（enabled = false）
- `using-superpowers` は `~/.claude/skills/` に入れる
- カスタム版（`_claude/` オーバーレイ）が勝つ
- 別 PC でも `install-claude.ps1` を走らせれば同じ状態になる

## 非目標

- `install.ps1` / `~/.agents` / Cursor / Codex の変更
- Codex 側 Superpowers プラグインの無効化
- marketplace 登録（`extraKnownMarketplaces`）の削除
- プラグイン cache の削除
- `requesting-code-review` / `receiving-code-review` / `using-git-worktrees` を `.claude/skills` に入れること（Claude ネイティブ `/code-review` と worktree と二重になる）
- `_claude/` オーバーレイ3つの中身変更
- `docx` / `pdf` / `pptx` / `xlsx` / `skill-creator` の除外解除

## 正本

| 対象 | 正本 | Claude での供給 |
|------|------|-----------------|
| Superpowers 本体（TDD / writing-plans / brainstorming 等） | skills-pack | `~/.claude/skills/`（必要なら `_claude/` オーバーレイ） |
| `using-superpowers` | skills-pack | `~/.claude/skills/using-superpowers/`（今回から入れる） |
| code review | Claude ネイティブ `/code-review` | スキルフォルダには置かない |
| git worktree | Claude ネイティブ worktree | スキルフォルダには置かない |
| Superpowers プラグイン | 使わない | `enabledPlugins` を false |

Cursor / Codex は従来どおり `~/.agents/skills/`（`using-superpowers` 含む）。Claude は `~/.agents` を読まない。

## インストーラ挙動

`skills-pack/install-claude.ps1` のみ。別スクリプトは作らない。

### 除外リスト（8件）

```
docx, pdf, pptx, xlsx, skill-creator,
requesting-code-review, receiving-code-review, using-git-worktrees
```

`using-superpowers` を除外から外す。既存どおり、除外名が `~/.claude/skills/` にあれば削除する。

除外理由をコメントで分ける:

- 公式プラグインと重複: `docx` `pdf` `pptx` `xlsx` `skill-creator`
- Claude ネイティブと重複: `requesting-code-review` `receiving-code-review` `using-git-worktrees`
- Superpowers プラグインはスキル除外ではなく `settings.json` で無効化する

### プラグイン無効化

スキルコピー・除外削除・オーバーレイ適用のあと、`%USERPROFILE%\.claude\settings.json` を処理する。

1. ファイルが無い → 何もしない（WARNING）
2. `enabledPlugins["superpowers@superpowers-marketplace"]` キーが **無い** → 何もしない
3. キーがある → 書き込み前に同ディレクトリへ `settings.json.bak` を上書きコピーし、値を `false` にする
4. `extraKnownMarketplaces` と `~/.claude/plugins/cache/` は触らない

PowerShell `ConvertTo-Json` で整形（インデント・キー順）が変わるのは許容。`enabledPlugins` の当該キー以外の値は変えない。`-Depth` は 20 以上。

キーが既に `false` なら bak も書き込みもしない（冪等）。

### この PC

実装後に `install-claude.ps1` を実行する。Claude Code 再起動が必要。

## ドキュメント

件数は手で固定しない。`install-claude.ps1` は MANIFEST ではなく pack 内の `SKILL.md` を走査する。Claude 件数の正はインストーラ出力の `Unique skills installed`。実装時にその数字でドキュメントを揃え、以降も「除外8」とインストーラ出力を正にする（47/48/56 などを再ハードコードしない）。

現状の嘘（除外9 / 47 / 48 が混在）は今回まとめて直す。

| ファイル | 内容 |
|----------|------|
| `skills-pack/install-claude.ps1` | 除外8、プラグイン無効化、コメント修正 |
| `skills-pack/INSTALL.md` | 除外リスト、プラグインを使うな、インストーラが enabled を落とす。Cursor 向け「別 PC に Superpowers プラグイン」注記は残す（`install.ps1` 側） |
| `skills-pack/引き継ぎ.md` | 3b の除外説明、確認表、件数 |
| `skills一覧.md` | Claude 行の除外数と件数 |
| `skills-pack/skills重複処理.md` | Claude 側は `install-claude.ps1` 再実行でプラグインも false になる旨を1行 |

文言の核:

- Claude の Superpowers 正本は pack。`/add-plugin superpowers` は Claude でも使うな
- `using-superpowers` は `.claude/skills` に **ある** のが正常
- review / worktree の3つが **無い** のが正常

## 成功条件

1. `~/.claude/settings.json` の `superpowers@superpowers-marketplace` が `false`（キーがある場合）
2. `~/.claude/skills/using-superpowers/SKILL.md` が存在する
3. 除外8が `~/.claude/skills/` に無い
4. `_claude/` オーバーレイ3つは従来どおり当たる
5. `~/.agents` と Cursor / Codex は変化しない
6. `install-claude.ps1` の再実行が冪等（enabled が既に false なら settings を書き換えない）
7. ドキュメントから「除外9」「using-superpowers は Claude に無い」が消える

## 検証

- `$excludeSkills` に `using-superpowers` が無い。8件の名前が残っている
- プラグイン無効化が `enabledPlugins` の当該キーだけを見る（marketplace / cache を消さない）
- settings が無い・キーが無い・既に false の3分岐をコード上確認
- この PC でインストーラ実行後: 上記成功条件 1–4 を実ファイルで確認
- Claude Code 再起動後、`/using-superpowers` が1件、`/writing-plans` が1件

## 失敗しやすい点

- Claude Code を再起動しないとプラグイン無効が UI に出ない
- `ConvertTo-Json` で JSON 整形が変わる。中身のキー欠落が無いか bak と比較する
- 件数をまた手で固定すると、次のスキル追加でまた嘘になる。除外は「8件」と名前、件数はインストーラ出力を正にする
- Cursor の Include Third-Party トグルは `.claude` 由来の表示を隠すだけで、Claude Code 自身の二重は消えない
