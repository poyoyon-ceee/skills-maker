# Claude Superpowers 二重解消 — 実装計画

> **For agentic workers:** タスク順に実装。ユーザーが commit を頼むまで commit しない。
> Spec: `docs/superpowers/specs/2026-08-19-claude-superpowers-dedupe-design.md`

**Goal:** Claude Code の Superpowers 正本を skills-pack に一本化する（プラグイン OFF、`using-superpowers` を `.claude/skills` に入れる）。

**Architecture:** `install-claude.ps1` の除外リストから `using-superpowers` を外し、同スクリプトで `~/.claude/settings.json` の `enabledPlugins["superpowers@superpowers-marketplace"]` を false にする。Cursor / `install.ps1` は触らない。

**Tech stack:** PowerShell 5.1+ / Markdown docs

## Global Constraints

- commit しない（ユーザー指示があるまで）
- `extraKnownMarketplaces` と plugin cache は削除しない
- review / worktree / office / skill-creator の除外は残す
- `_claude/` オーバーレイは変更しない
- 件数はインストーラの `Unique skills installed` を正にする（47/48 を再ハードコードしない）

---

### Task 1: install-claude.ps1

**Files:**
- Modify: `skills-pack/install-claude.ps1`

- [ ] ヘッダコメントを除外理由3種に書き換え（公式プラグイン / Claude ネイティブ / Superpowers は settings で無効）
- [ ] `$excludeSkills` から `using-superpowers` を削除（8件）
- [ ] `Disable-SuperpowersPlugin` を追加し、`Install-ToRoot` ループのあとで1回呼ぶ
- [ ] キー無し・ファイル無し・既に false → no-op。true のときだけ `settings.json.bak` を書いて false
- [ ] `ConvertTo-Json -Depth 20`、UTF-8 BOM なしで書き戻す

### Task 2: この PC でインストーラ実行

- [ ] `skills-pack\install-claude.ps1` を実行
- [ ] `Unique skills installed` を記録
- [ ] 成功条件 1–4 を実ファイルで確認（plugin false、using-superpowers あり、除外8なし、オーバーレイ残存）
- [ ] 再実行して settings が冪等（bak 時刻が変わらない / "already disabled"）

### Task 3: ドキュメント

**Files:**
- Modify: `skills-pack/INSTALL.md`
- Modify: `skills-pack/引き継ぎ.md`
- Modify: `skills一覧.md`
- Modify: `skills-pack/skills重複処理.md`

- [ ] 除外8の名前を書く。`using-superpowers` は Claude に **ある** のが正常
- [ ] Claude 件数を Task 2 の `Unique skills installed` に揃える
- [ ] `/add-plugin superpowers` は Claude でも使うな。インストーラが enabled を落とす
- [ ] Cursor 向け「`install.ps1` 後に Superpowers プラグインで二重」注記は残す
- [ ] `skills重複処理.md` に、再実行でプラグインも false になる旨を1行
