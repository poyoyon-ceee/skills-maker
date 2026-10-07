---
name: promote-skill
description: >-
  Use immediately after create-skill, skill-creator, or any new/edited Agent Skill
  is written to disk. Use when the user finishes making a skill, asks to install a
  skill globally, or mentions skills-pack / 同期 / 入れる. Place the skill in one
  of the four incoming boxes and run scripts/sync-incoming.ps1 — do not hand-copy
  to global and pack. Works in Cursor and Claude Code.
---

# Promote Skill（作成後の inbox 同期）

スキル作成・編集の**直後に必ず**このフローを走らせる。作成スキル本体（create-skill / skill-creator）の締めとして扱う。Cursor でも Claude Code でも同じ手順。

**4箱・`installTargets`・catalog キーの正本:** リポジトリの [incoming/RULES.md](../../incoming/RULES.md)（skills-maker 外に clone している場合はその `incoming/RULES.md`）。

## 絶対ルール

1. **手で `~/.agents` / `~/.cursor` / `skills-pack` へコピーして登録を終わらせない。** 登録は `scripts/sync-incoming.ps1` だけ。
2. **skills-maker ルートを推測で新規作成しない。** 検証に失敗したら書かない。
3. **git commit / push しない**（ユーザーが明示したときだけ）。
4. マーケ専用は `skills-pack-marketing`（ユーザーがマーケと言ったときのみ）。通常は `skills-pack`（inbox 同期の出力先）。
5. **`~/.agents` と `~/.cursor` に同じスキルを置かない。**（Cursor が二重登録する）

## 置き場所（incoming 4箱）

| 箱 | installTargets |
|---|---|
| `incoming/agents-claude/` | agents + claude |
| `incoming/agents-only/` | agents のみ |
| `incoming/claude-only/` | claude のみ |
| `incoming/cursor-only/` | cursor のみ |

- フォルダ名 = `SKILL.md` の `name`。一致しなければ同期しない。
- `agents` は Cursor・Codex・ChatGPT 系。**GPT 専用ではない。**
- **`agents` と `cursor` を同時に選ばない。**
- 会話内で作ったスキルで inbox をまだ使っていない → **4箱のどれかをユーザーに確認**してから、その箱へ置く。

## フロー

```text
スキル作成完了
  → 4箱のどれかへ `<name>/` フォルダを置く（既に inbox にあるならこのステップはスキップ可）
  → 「同期する？」と確認（ユーザーが同期を依頼済みならそのまま実行可）
      No  → inbox に残したまま終了
      Yes → skills-maker パス解決 → 検証 OK のときだけ sync-incoming.ps1
```

inbox にスキルがあるときは **`scripts/sync-incoming.ps1` だけ** で pack・MANIFEST・一覧・グローバルへ反映する（手コピー登録は使わない）。

## パス解決（誤書き防止）

順番:

1. ユーザーがこの会話で既に渡した skills-maker パス
2. 環境変数 `SKILLS_MAKER_ROOT`（セットされていて、かつ検証 OK のときだけ）
3. デフォルト候補: skills-maker リポジトリ（**存在するときだけ**。無ければ使わない）
4. どれもダメ → **「skills-maker のパスは？」と聞く。来るまで sync は実行しない**（検証に通らないルートへは一切書き込まない）

### 検証（全部満たすこと）

パス `$ROOT` が skills-maker と認められる条件:

- `$ROOT` が既存ディレクトリ
- `$ROOT/skills-pack/` が既存ディレクトリ
- 次の**どれか1つ以上**が `$ROOT/skills-pack/` にある: `install.ps1` / `MANIFEST.json` / `引き継ぎ.md`

不合格なら:

- **一切書き込まない**（`$ROOT` や `skills-pack` を新規作成しない）
- 理由を伝え、正しいパスを再質問する

## 同期の実行

検証済み `$ROOT` で **inbox 内の全スキル**を処理する（1件だけのつもりでも、他の inbox スキルも一緒に走る点に注意）。

```powershell
cd "<verified-root>"
.\scripts\sync-incoming.ps1
```

- exit ≠ 0 → 失敗したスキルは inbox に残る。出力をユーザーに報告して止める（勝手に手コピーでフォールバックしない）。
- `catalog-section` / `catalog-summary` / `catalog-when` が無いスキルは同期されない（RULES 参照）。

## 完了報告

- 同期した / しなかった
- スクリプトの成否と、更新された pack・グローバル・一覧の要点
- 「commit するなら指示して」と一言（勝手に commit しない）

## やってはいけないこと

- 確認なしで黙って sync
- skills-maker リポジトリが無いのに作成する
- 検証前に `skills-pack` 配下へ手コピー
- **global と pack の両方へ手でコピーして登録を終える**
- `sync-skills-pack.ps1` の全件ミラーをこのフローの既定にする（実験スキル混入の原因）
- `~/.cursor/skills-cursor/` へ書く
- **`~/.agents/skills` と `~/.cursor/skills` の両方に同じスキルを置く**（設定画面と `/` メニューの件数がズレ、編集しても効かない側が残る）
- インストール先に `playbooks/` のようなカテゴリフォルダを作る（pack 内の整理用であって、配置先では平置き）
