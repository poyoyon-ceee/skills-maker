# incoming 同期 Implementation Plan

> **状態（2026-10-07）:** 下のチェックは未更新のまま。実装の正本は `incoming/RULES.md`、`scripts/sync-incoming.ps1`、`scripts/incoming_lib.py`、`tests/`。チェックを完了の記録として読まない。

> **For Claude Code agent:** Implement task-by-task. Use TDD (test-driven-development skill).
> Track progress with checkbox (`- [ ]`) syntax.

**Goal:** `incoming/` の4箱にスキルを置き、「同期して」で global・skills-pack・MANIFEST・`skills一覧.md`・PDF が同じ結果になる。

**Architecture:** 受付は `incoming/` の4箱だけ。宛先の正本は `MANIFEST.json` の `installTargets`（`agents` / `claude` / `cursor` の配列）。`installTarget` 文字列は古い読み手用の派生値で、インストーラは読まない。一覧の1行はスキル frontmatter の `catalog-section` / `catalog-summary` / `catalog-when` から作り、同じ処理で PDF を再生成する。手順の全文は `incoming/RULES.md` だけが持つ。

**Tech Stack:** Python 3（検査・一覧更新）、PowerShell（このPCの実行入口）、既存 `scripts/generate_skills_catalog_pdf.py`。bash の `install.sh` と `promote-to-pack.sh` も同じ規則に合わせる。

## Global Constraints

- git commit / push / amend をしない。ユーザーが明示するまでコミットしない。
- 同じスキルを `~/.agents/skills` と `~/.cursor/skills` の両方に置かない。`installTargets` に `agents` と `cursor` が同時にある行は不正。
- `~/.agents` と `~/.claude` の併置は可。`cursor` と `claude` の併置は、既存の `chat-handoff` と `promote-skill` だけ。新規の受付箱は作らない。
- inbox のフォルダ名は次の4つのみ。日本語名は作らない: `agents-claude`, `agents-only`, `claude-only`, `cursor-only`。
- `installTargets` のトークンは `agents`, `claude`, `cursor` だけ。並びは常に `agents`, `cursor`, `claude` の順で、存在するトークンだけを残す。だから `cursor` と `claude` は `["cursor", "claude"]` になる。`agents` と `cursor` の同時指定は、この順でも不正。
- テストは本物の `%USERPROFILE%\.agents` / `.cursor` / `.claude` に書かない。宛先は引数で差し替える。
- `skills-pack-marketing/`、手製の pptx / docx / `archive/組合わせ.xlsx` は変更しない。
- Windows では PowerShell。`cmd /c` は使わない。
- 再生成で既存スキルの `installTargets` を名前リストから推測して上書きしない。
- YAML の `name: "00"` は JSON では `"00"`。引用符を名前の一部にしない。`installTarget` も `~/.agents/skills/00/`。
- 一覧の `catalog-when` が `—` の行は作らない（PDF が捨てる）。
- 検査が失敗したら inbox のそのスキルは消さない。

### 宛先の対応

| 箱 | `installTargets` |
|---|---|
| `incoming/agents-claude/` | `["agents", "claude"]` |
| `incoming/agents-only/` | `["agents"]` |
| `incoming/claude-only/` | `["claude"]` |
| `incoming/cursor-only/` | `["cursor"]` |

派生 `installTarget`（インストーラは使わない）:

- `agents` がある → `~/.agents/skills/<name>/`
- それが無く `cursor` がある → `~/.cursor/skills/<name>/`
- それも無く `claude` だけ → `~/.claude/skills/<name>/`

### 既存スキルの移行マップ（推測禁止。この表だけ）

- `["cursor"]`: `skill-creator`
- `["cursor", "claude"]`: `chat-handoff`, `promote-skill`
- `["agents"]`: `docx`, `pdf`, `pptx`, `xlsx`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `model-router-gpt`
- 上に無い既存スキルはすべて `["agents", "claude"]`。`00` と `youtube-music-playlist` と `x-reader` を含む。

`skills一覧.md` に無いのは、確認済みで次の3件だけ: `model-router-gpt`, `x-reader`, `youtube-music-playlist`。ほかが見つかったら止めて報告する。行はすべて `## 5.` の表へ入れる。

| name | catalog-summary | catalog-when |
|---|---|---|
| `model-router-gpt` | CodexのGPTモデルへ、大量の原文を読む調査を渡す | リポジトリ全体や大量の文書・ログから根拠を探すとき。少数ファイルの確認には使わない |
| `x-reader` | 内蔵ブラウザで x.com / twitter.com の投稿本文と添付を読む | x.com または twitter.com の投稿URLを読んで、開いて、確認して、要約してほしいとき |
| `youtube-music-playlist` | 曲リストのURLから再生リストへ追加し、曖昧な曲は保留して保存先で確認する | 渡された曲リストやYouTube Musicのリンクを、ログイン済みブラウザの再生リストへ追加・再開するとき |

---

### Task 1: 宛先バリデータ

**Files:**
- Create: `scripts/incoming_lib.py`
- Test: `tests/incoming_sync_test.py`

**Interfaces:**
- Produces: `targets_for_box(box: str) -> list[str]`
- Produces: `validate_targets(targets: list[str]) -> list[str]`
- Produces: `legacy_install_target(targets: list[str], name: str) -> str`

- [ ] **Step 1: Write the failing test**

`tests/incoming_sync_test.py`:

```python
import unittest
from scripts.incoming_lib import legacy_install_target, targets_for_box, validate_targets


class TargetsTest(unittest.TestCase):
    def test_boxes(self):
        self.assertEqual(targets_for_box("agents-claude"), ["agents", "claude"])
        self.assertEqual(targets_for_box("agents-only"), ["agents"])
        self.assertEqual(targets_for_box("claude-only"), ["claude"])
        self.assertEqual(targets_for_box("cursor-only"), ["cursor"])

    def test_unknown_box(self):
        with self.assertRaises(ValueError):
            targets_for_box("gpt-only")

    def test_agents_and_cursor_rejected(self):
        with self.assertRaises(ValueError):
            validate_targets(["agents", "cursor"])

    def test_empty_rejected(self):
        with self.assertRaises(ValueError):
            validate_targets([])

    def test_unknown_token_rejected(self):
        with self.assertRaises(ValueError):
            validate_targets(["gpt"])

    def test_order_is_canonical(self):
        self.assertEqual(validate_targets(["claude", "agents"]), ["agents", "claude"])
        self.assertEqual(validate_targets(["cursor", "claude"]), ["cursor", "claude"])

    def test_legacy_paths(self):
        self.assertEqual(
            legacy_install_target(["agents", "claude"], "foo"),
            "~/.agents/skills/foo/",
        )
        self.assertEqual(
            legacy_install_target(["cursor"], "skill-creator"),
            "~/.cursor/skills/skill-creator/",
        )
        self.assertEqual(
            legacy_install_target(["claude"], "bar"),
            "~/.claude/skills/bar/",
        )
        self.assertEqual(
            legacy_install_target(["cursor", "claude"], "promote-skill"),
            "~/.cursor/skills/promote-skill/",
        )


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run from repo root: `python -m unittest tests.incoming_sync_test -v`

Expected: FAIL with `ModuleNotFoundError` or `ImportError` for `scripts.incoming_lib`.

- [ ] **Step 3: Write minimal implementation**

`scripts/incoming_lib.py` exports the three functions. `targets_for_box` uses the four-box table above. `validate_targets` rejects empty, unknown tokens, and `agents`+`cursor`. Canonical order is `agents`, `cursor`, `claude`（`["cursor", "claude"]` を崩さない）。`legacy_install_target` calls `validate_targets` first, then the precedence above. Add `scripts/__init__.py` only if the import requires it.

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m unittest tests.incoming_sync_test -v`

Expected: PASS, 7 tests.

Do not commit.

### Task 2: MANIFEST に installTargets を足す

**Files:**
- Modify: `scripts/generate-manifest.ps1`
- Modify: `skills-pack/promote-skill/scripts/promote-to-pack.ps1`
- Modify: `skills-pack/promote-skill/scripts/promote-to-pack.sh`
- Modify: `skills-pack/MANIFEST.json`
- Modify: `skills-pack/project-foundation/tests/manifest.test.js`
- Test: `tests/incoming_sync_test.py`（移行マップの期待値を足す）
- Modify: `scripts/incoming_lib.py`（`migration_targets(name: str) -> list[str]` を足す）

**Interfaces:**
- Consumes: `validate_targets`, `legacy_install_target`
- Produces: `migration_targets(name: str) -> list[str]`
- Produces: 各 MANIFEST エントリの `installTargets` と、引用符を剥がした `name`

- [ ] **Step 1: Write the failing test**

`migration_targets` について次を追加する。

- `skill-creator` → `["cursor"]`
- `chat-handoff` と `promote-skill` → `["cursor", "claude"]`
- `docx` と `model-router-gpt` → `["agents"]`
- `00`, `youtube-music-playlist`, `brainstorming` → `["agents", "claude"]`
- 未知の名前 `brand-new-skill` は `ValueError`（既定で agents+claude と決めない）

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m unittest tests.incoming_sync_test -v`

Expected: FAIL on missing `migration_targets`.

- [ ] **Step 3: Implement migration helper and manifest writers**

`migration_targets` は Global Constraints の移行マップだけを持つ。マップに無い名前は `ValueError`。

`generate-manifest.ps1`:

- `name:` の引用符を剥がす（既存の `Get-SkillName` を維持）。
- 既存 `MANIFEST.json` に同じ `name` の `installTargets` があればそれを使う。
- 無く、`migration_targets` に該当する名前ならその配列を使う。PowerShell 内に同じマップを重複して書かず、`python -c` で `scripts.incoming_lib.migration_targets` を呼ぶ。
- どちらも無ければ exit 1。推測しない。
- `installTarget` は `legacy_install_target` の結果。
- 出力オブジェクトのキー順: `name`, `path`, `installTargets`, `installTarget`。
- `$cursorOnlySkills` で宛先を決める処理を削除する。

`promote-to-pack.ps1` と `.sh` の MANIFEST 再生成も同じ規則。新規スキルで既存エントリも移行マップも無いときは exit 1。メッセージは `incoming sync required; refusing to guess installTargets`。引用符剥がしもこちらに入れる。

その後、リポジトリルートで `.\scripts\generate-manifest.ps1` を実行し `skills-pack/MANIFEST.json` を更新する。

`manifest.test.js` は既存の `00` の `installTarget` アサーションを残し、次を足す。

- `00`.installTargets が `["agents", "claude"]`
- `skill-creator`.installTargets が `["cursor"]`
- `chat-handoff`.installTargets が `["cursor", "claude"]`
- どの行も `agents` と `cursor` を同時に含まない
- `name` が `00` であり `"00"` という文字を含まない（JSON パース後の値）

- [ ] **Step 4: Run tests**

Run:

```powershell
python -m unittest tests.incoming_sync_test -v
node --test skills-pack/project-foundation/tests/manifest.test.js
```

Expected: both PASS.

Do not commit.

### Task 3: インストーラを installTargets 基準にする

**Files:**
- Modify: `skills-pack/install.ps1`
- Modify: `skills-pack/install.sh`
- Modify: `skills-pack/install-claude.ps1`
- Test: `tests/incoming_sync_test.py` には足さない。インストーラ用に `tests/install_targets_test.ps1` を作る

**Interfaces:**
- Consumes: `skills-pack/MANIFEST.json` の `installTargets`
- `install.ps1` / `install.sh` は任意の `-AgentsDest` と `-CursorDest`（sh は環境変数 `AGENTS_DEST` と `CURSOR_DEST`）が無いときだけ `%USERPROFILE%\.agents\skills` と `%USERPROFILE%\.cursor\skills`
- `install-claude.ps1` は任意の `-ClaudeDest`。無いときだけ `%USERPROFILE%\.claude\skills`

- [ ] **Step 1: Write the failing test**

`tests/install_targets_test.ps1` は一時ディレクトリを宛先にする。pack のコピーは作らず、本番 `skills-pack` に対して宛先だけ差し替えて実行する。

期待:

- `youtube-music-playlist\SKILL.md` が AgentsDest にあり、CursorDest に無い
- `skill-creator\SKILL.md` が CursorDest にあり、AgentsDest に無い
- `promote-skill\SKILL.md` が CursorDest にあり、AgentsDest に無い
- ClaudeDest に `youtube-music-playlist\SKILL.md` と `promote-skill\SKILL.md` があり、`docx` と `model-router-gpt` と `skill-creator` が無い
- テストは `%USERPROFILE%\.agents` 等の本物を変更していない（開始時と終了時の `youtube-music-playlist` の有無が同じ）

フック（`_hooks`）のコピーはテスト宛先に含めない。`install.ps1` に `-SkipHooks` を足し、テストはそれを付ける。本番の引数なし実行は今までどおりフックも入れる。

- [ ] **Step 2: Run test to verify it fails**

テストは「差し替え引数が無く、現状の `$cursorOnlySkills` のまま」では Claude 側の期待が落ちる。先にテストを書き、引数が未実装なら失敗することを確認してから実装する。

- [ ] **Step 3: Implement**

ルーティング:

- MANIFEST を読む。`installTargets` が無い行は exit 1。
- `agents` かつ `cursor` の行は exit 1。
- `install.ps1`: `agents` なら AgentsDest、`cursor` なら CursorDest へ、そのスキルのディレクトリを平置きコピー。カテゴリフォルダは今どおり剥がす。
- `install-claude.ps1`: `claude` があるスキルだけ ClaudeDest へコピー。`claude` が無い名前は ClaudeDest に残っていれば削除する。`$excludeSkills` の名前リストは削除する。`_claude/` オーバーレイは今どおり。
- ハードコードの `$cursorOnlySkills` は削除する。

`install.sh` も同じ振り分け。環境変数が空なら `$HOME/.agents/skills` と `$HOME/.cursor/skills`。

- [ ] **Step 4: Run the test**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\install_targets_test.ps1`

Expected: PASS。本物のホームは不変。

Do not commit.

### Task 4: skills一覧.md と PDF を同じ処理で更新する

**Files:**
- Modify: `scripts/incoming_lib.py`
- Modify: `tests/incoming_sync_test.py`
- Modify: `skills-pack/model-router-gpt/SKILL.md`（frontmatter に3項目を足すだけ）
- Modify: `skills-pack/x-reader/SKILL.md`（同上）
- Modify: `skills-pack/youtube-music-playlist/SKILL.md`（同上）
- Modify: `skills一覧.md`（関数の出力だけ）
- Modify: `catalog/skills-catalog-system-atlas.pdf`（既存ジェネレータの出力だけ）

**Interfaces:**
- Produces: `upsert_catalog_row(markdown: str, section: int, command: str, summary: str, when: str) -> str`
- Produces: `recount_section_headings(markdown: str) -> str`
- Produces: `missing_manifest_names(manifest_names: list[str], markdown: str) -> list[str]`

- [ ] **Step 1: Write the failing test**

一時文字列で:

- `## 5. 独自（1件）` の表に `/aaa` がある状態へ `/mmm` を入れると、`/aaa` の次に `/mmm` が来る
- 見出しの件数は表の行数になる（参照行を除く。使いどころが `—` の行は件数に入れず、関数は `—` を `ValueError` で拒む）
- `missing_manifest_names(["aaa", "zzz"], markdown)` は `zzz` だけを返す
- コマンドセルが `` `/name`（手動のみ） `` でも `name` は存在する扱い

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement and backfill the three skills**

3スキルの frontmatter に、この計画の表どおり `catalog-section: 5` と summary と when を足す。本文は変えない。

`upsert_catalog_row` は `## {section}.` の最初の表（`| コマンド | 説明 | 使いどころ |`）に、コマンド名のアルファベット順で挿入する。同じ `/name` が既にあればその行を置き換える。見出しの `（N件）` は、その `##` 節に含まれるデータ行（使いどころが `—` でない行）の数で書き換える。節内の `###` 表も数に含める。

次を実行する。

1. 3スキルの frontmatter を読む
2. `skills一覧.md` を更新する
3. `python scripts/generate_skills_catalog_pdf.py`
4. `missing_manifest_names` が空であること
5. PDF の更新時刻が `skills一覧.md` 以上であること

ほかの MANIFEST 名が欠けていたら、行を足さず止める。

- [ ] **Step 4: Run tests**

`python -m unittest tests.incoming_sync_test -v` が PASS。PDF 生成が exit 0。

Do not commit.

### Task 5: 同期スクリプト

**Files:**
- Create: `scripts/sync-incoming.ps1`
- Create: `incoming/agents-claude/.gitkeep`
- Create: `incoming/agents-only/.gitkeep`
- Create: `incoming/claude-only/.gitkeep`
- Create: `incoming/cursor-only/.gitkeep`
- Create: `incoming/RULES.md` は Task 6。ここは空の箱だけ
- Test: `tests/sync_incoming_test.ps1`

**Interfaces:**
- Consumes: `targets_for_box`, `validate_targets`, `upsert_catalog_row`, MANIFEST 再生成
- `sync-incoming.ps1` は `-RepoRoot` と `-HomeRoot` を受け取る。`-HomeRoot` が無いときは `%USERPROFILE%`。テストは一時 HomeRoot を渡す

- [ ] **Step 1: Write the failing test**

一時リポジトリを本番から丸コピーしない。テストは本番スクリプトを、次の最小構成に対して `-RepoRoot` で実行する。

- `incoming/agents-claude/sample-skill/SKILL.md`（name と catalog 3項目あり、section は 5）
- 最小の `skills一覧.md`（`## 5.` の空に近い表）
- 最小の `skills-pack/MANIFEST.json`（`[]` または既存1件）
- `scripts/incoming_lib.py` は本番を使う

期待:

- 成功後、`HomeRoot\.agents\skills\sample-skill\SKILL.md` と `HomeRoot\.claude\skills\sample-skill\SKILL.md` がある
- `HomeRoot\.cursor\skills\sample-skill` は無い
- `RepoRoot\skills-pack\sample-skill\SKILL.md` がある
- MANIFEST のその行の `installTargets` が `["agents", "claude"]`
- `skills一覧.md` に `/sample-skill` がある
- `incoming/agents-claude/sample-skill` は消えている
- catalog 項目を欠いたスキルは inbox に残り、exit code が 0 でない
- `agents` と `cursor` を同時に要求する箱は存在しないので、箱名 `bogus/` に置いたスキルは exit code が 0 でない（4箱以外のディレクトリにスキルがあっても、スクリプトはそれを読まない。テストは未知の箱名を `-Box` で渡したら失敗、とせず、4箱以外の兄弟フォルダ `incoming/extra/skill` があっても無視し、4箱だけ処理する）

PDF 生成はテストでは `-SkipPdf`。本番の引数なしは PDF まで行う。PDF 生成失敗時は inbox を残し、そのスキルの pack コピーと global コピーを戻す。

戻し方: コピー前に宛先が無ければ削除。あればコピー前のディレクトリを一時退避して戻す。pack も同じ。

- [ ] **Step 2: Run test to verify it fails**

スクリプトが無いので FAIL。

- [ ] **Step 3: Implement `scripts/sync-incoming.ps1`**

処理順は計画の Goal どおり。

1. `incoming` 直下は4箱と `RULES.md` 以外のファイルがあっても、スキルとしては読まない。4箱の各直下だけ `<skill>/SKILL.md` を探す
2. frontmatter に `catalog-section` `catalog-summary` `catalog-when` が無ければ、そのスキルを失敗にして inbox に残す。他のスキルは続けてよい。最後に失敗が1件でもあれば exit 1
3. `skills-pack/<skill>/` へフォルダコピー（カテゴリは付けない）
4. 箱から `installTargets` を決め、`generate-manifest.ps1` が保持できるよう、コピーした `SKILL.md` には書かず、MANIFEST 更新前に既存 MANIFEST へその名前の `installTargets` を書いてから再生成する。再生成は保持規則に従う
5. 宛先 global へ平置きコピー
6. `skills一覧.md` を更新
7. `-SkipPdf` でなければ `python scripts/generate_skills_catalog_pdf.py`
8. ここまで成功したスキルだけ inbox から削除

同名が pack に既にあるときは、inbox の中身で上書きする前にテストでその挙動を固定する: 上書きしてよい。ただし `installTargets` は箱の値で置き換える。

- [ ] **Step 4: Run `tests/sync_incoming_test.ps1`**

Expected: PASS。本物のホームは不変。

Do not commit.

### Task 6: ルールブックを1枚にする

**Files:**
- Create: `incoming/RULES.md`
- Modify: `skills-pack/promote-skill/SKILL.md`
- Modify: `SETUP.md`
- Modify: `skills-pack/INSTALL.md`
- Modify: `catalog/README.md`
- Modify: `skills一覧.md` の補足（リンク1行）

- [ ] **Step 1: ルール全文を `incoming/RULES.md` に書く**

含めること:

- 新規スキルは4箱のどれかへ置く。日本語の箱は作らない
- 登録は「同期して」のあと `scripts/sync-incoming.ps1` だけ。手で `~/.agents` や pack へコピーしない
- 4箱とトークンの表
- `agents` は Cursor も Codex も ChatGPT も読む。GPT専用ではない
- `agents` と `cursor` の同時指定は禁止
- `chat-handoff` と `promote-skill` は既存の `["cursor", "claude"]`。箱は増やさない
- `catalog-section` / `catalog-summary` / `catalog-when` が無いスキルは同期しない。inbox に残る
- 手順の全文を他ファイルへ複製しない

- [ ] **Step 2: 他文書はリンクだけ**

`promote-skill/SKILL.md`: inbox にスキルがあるとき、Gate 1/2 の手コピーの代わりに `scripts/sync-incoming.ps1` を実行する、と書く。会話の中で作ったスキルで inbox を使わない場合は、4箱のどれかを聞いてからその箱へ置いて同じスクリプトを実行する。手で global と pack の両方へコピーして終わらせる手順は削除する。

`SETUP.md` の「新しいスキルを追加するとき」は `incoming/RULES.md` へのリンクと、同期コマンド1行に置き換える。

`skills-pack/INSTALL.md` と `catalog/README.md` と `skills一覧.md` の補足は、宛先の正本が `installTargets` であること、一覧と PDF は同期スクリプトが更新すること、詳細は `incoming/RULES.md`、の短文だけ足す。既存のインストール手順（別PCの `install.ps1`）は残す。

- [ ] **Step 3: 検査**

`incoming/RULES.md` に4つの箱名がすべてある。`promote-skill/SKILL.md` が `sync-incoming.ps1` を指している。`SETUP.md` が `incoming/RULES.md` を指している。

Do not commit.

## Self-review

- 4箱同期: Task 5
- 一覧と PDF: Task 4 と Task 5
- 複数宛先: Task 1–3
- AI 向けルール: Task 6
- コミットしない制約は全タスクに書いた
- `brand-new-skill` を移行マップの既定にしない、と Task 2 に書いた
- プレースホルダは置いていない。3件の一覧文言はこのファイルの表が正
