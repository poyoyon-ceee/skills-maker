---
name: promote-skill
description: >-
  Use immediately after create-skill, skill-creator, or any new/edited Agent Skill
  is written to disk. Use when the user finishes making a skill, asks to install a
  skill globally, or mentions skills-pack / 同期 / 入れる. Always run the two
  confirmation gates (global first, then pack sync) — do not skip even if the
  user did not say "promote". Works in Cursor and Claude Code.
---

# Promote Skill（作成後の global / skills-pack 反映）

スキル作成・編集の**直後に必ず**このフローを走らせる。作成スキル本体（create-skill / skill-creator）の締めとして扱う。Cursor でも Claude Code でも同じ手順。

## 絶対ルール

1. **確認は2段。まとめない。**
2. **skills-maker ルートを推測で新規作成しない。** 検証に失敗したら書かない。
3. **git commit / push しない**（ユーザーが明示したときだけ）。
4. マーケ専用は `skills-pack-marketing`（ユーザーがマーケと言ったときのみ）。通常は `skills-pack`。
5. **`~/.agents` と `~/.cursor` に同じスキルを置かない。**（Cursor が二重登録する）

## 置き場所の決め方（重複防止の要）

| 条件 | 宛先 |
|------|------|
| 通常のスキル（IDE 非依存） | `~/.agents/skills/<skill-folder-name>/` |
| Cursor 固有（`~/.cursor` パス・Cursor UI・Cursor 用 PowerShell を前提にする） | `~/.cursor/skills/<skill-folder-name>/` |
| Claude Code で今すぐ使う | `~/.claude/skills/<skill-folder-name>/` |

- `~/.agents/skills` は Cursor・Codex・ChatGPT 系が共通で読む。**原則こっち**
- `~/.claude/skills` は Claude Code だけが読む。Claude 上で作ってすぐ使うならここ（必要なら `~/.agents` にもコピー可）
- **`~/.agents` と `~/.claude` の併置は可**（別ツールが読む。Cursor 二重登録にはならない）
- install 配置上 Cursor 固有なのは今も `chat-handoff` / `skill-creator` / `promote-skill` の3つ（`install.ps1` → `~/.cursor`）。ただし **本スキルの手順自体は Claude でも使う**（`install-claude.ps1` で `~/.claude` にも入る）
- **カテゴリのサブフォルダを作らない**（`playbooks/` 等）。Codex がネストを辿る保証がないため、インストール先は必ず平置き
- 判断に迷ったら `~/.agents/skills`。Claude でもすぐ使うなら `~/.claude/skills`

## フロー

```text
スキル作成完了
  → Gate 1「グローバルに入れる？」（宛先は上の表で決める）
      No  → 終了（project-local のまま等）。Gate 2 は出さない
      Yes → global に配置
  → Gate 2「skills-pack に同期する？」
      No  → global のみで終了
      Yes → skills-maker パス解決 → 検証 OK のときだけ pack へコピー + MANIFEST 更新
```

### Gate 1 — 入れる？（global）

質問例:

- 通常: 「このスキルを `~/.agents/skills/` に入れる？」
- Cursor 固有: 「`~/.cursor/skills/` に入れる？」
- Claude で今すぐ使う: 「`~/.claude/skills/` に入れる？」（agents にも置くかは別確認可）

Yes のとき:

1. ソース = いま書いたスキルフォルダ（`SKILL.md` を含むディレクトリ）
2. 宛先 = 「置き場所の決め方」の表で決めた root ＋ `<skill-folder-name>\`
   - 通常: `%USERPROFILE%\.agents\skills\<skill-folder-name>\`（macOS/Linux: `~/.agents/skills/...`）
   - Cursor 固有: `%USERPROFILE%\.cursor\skills\<skill-folder-name>\`
   - Claude: `%USERPROFILE%\.claude\skills\<skill-folder-name>\`
3. **`~/.agents` と `~/.cursor` に同名が無いことを確認**（あると Cursor が2回登録する）
4. 同名が既にある（選んだ root 内） → 上書き前に確認
5. フォルダごとコピー（`SKILL.md` 以外の scripts / references も含む）
6. 成功パスをユーザーに報告

No のとき: 何もコピーせず終了。

### Gate 2 — 同期する？（skills-pack）

**Gate 1 が Yes のときだけ**聞く。

質問例: 「`skills-pack` に同期する？」

Yes のとき → 下の「パス解決」→ スクリプト実行。  
No のとき → global のみで終了。

## パス解決（誤書き防止）

順番:

1. ユーザーがこの会話で既に渡した skills-maker パス
2. 環境変数 `SKILLS_MAKER_ROOT`（セットされていて、かつ検証 OK のときだけ）
3. デフォルト候補 `C:\Dev-App\skills-maker`（**存在するときだけ**。無ければ使わない）
4. どれもダメ → **「skills-maker のパスは？」と聞く。来るまで Gate 2 の書き込みをしない**

### 検証（全部満たすこと）

パス `$ROOT` が skills-maker と認められる条件:

- `$ROOT` が既存ディレクトリ
- `$ROOT/skills-pack/` が既存ディレクトリ
- 次の**どれか1つ以上**が `$ROOT/skills-pack/` にある: `install.ps1` / `MANIFEST.json` / `引き継ぎ.md`

不合格なら:

- **一切書き込まない**（`$ROOT` や `skills-pack` を新規作成しない）
- 理由を伝え、正しいパスを再質問する

## 同期の実行

検証済み `$ROOT` に対して、**その1スキルだけ**を pack へコピーする（global 全件ミラーはしない）。

### スクリプトの探し方（自己解決）

`promote-to-pack.ps1` / `promote-to-pack.sh` を次の順で探す。**最初に見つかったものを使う。** 無ければ止めて報告（勝手に別手段へフォールバックしない）。

1. いま従っているこの `promote-skill` フォルダの `scripts/`（隣）
2. `%USERPROFILE%\.claude\skills\promote-skill\scripts\`（`~/.claude/...`）
3. `%USERPROFILE%\.cursor\skills\promote-skill\scripts\`（`~/.cursor/...`）
4. `%USERPROFILE%\.agents\skills\promote-skill\scripts\`（将来用）

### Windows

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<resolved>\promote-to-pack.ps1" -SkillFolderName "<skill-folder-name>" -SkillsMakerRoot "<verified-root>"
```

マーケ pack のときだけ:

```powershell
# ... same ... -PackName "skills-pack-marketing"
```

### macOS / Linux

```bash
bash "<resolved>/promote-to-pack.sh" "<skill-folder-name>" "<verified-root>"
# marketing:
# bash "<resolved>/promote-to-pack.sh" "<skill-folder-name>" "<verified-root>" skills-pack-marketing
```

スクリプトが exit ≠ 0 なら書き込み失敗。勝手に別パスへリトライしない。ユーザーに報告して止める。

## 完了報告

- Gate 1/2 それぞれ Yes/No と実施有無
- global パス、pack パス（同期した場合）
- 「commit するなら指示して」と一言（勝手に commit しない）

## やってはいけないこと

- Gate を飛ばして黙って sync
- `C:\Dev-App\skills-maker` が無いのに作成する
- 検証前に `skills-pack` 配下へコピー
- `sync-skills-pack.ps1` の全件ミラーをこのフローの既定にする（実験スキル混入の原因）
- `~/.cursor/skills-cursor/` へ書く
- **`~/.agents/skills` と `~/.cursor/skills` の両方に同じスキルを置く**（設定画面と `/` メニューの件数がズレ、編集しても効かない側が残る）
- インストール先に `playbooks/` のようなカテゴリフォルダを作る（pack 内の整理用であって、配置先では平置き）
