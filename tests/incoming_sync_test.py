import unittest
from scripts.incoming_lib import (
    legacy_install_target,
    migration_targets,
    missing_manifest_names,
    recount_section_headings,
    targets_for_box,
    upsert_catalog_row,
    validate_targets,
)


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


class MigrationTargetsTest(unittest.TestCase):
    def test_cursor_only(self):
        self.assertEqual(migration_targets("skill-creator"), ["cursor"])

    def test_cursor_and_claude(self):
        self.assertEqual(migration_targets("chat-handoff"), ["cursor", "claude"])
        self.assertEqual(migration_targets("promote-skill"), ["cursor", "claude"])

    def test_agents_only(self):
        self.assertEqual(migration_targets("docx"), ["agents"])
        self.assertEqual(migration_targets("model-router-gpt"), ["agents"])

    def test_agents_and_claude_default(self):
        self.assertEqual(migration_targets("00"), ["agents", "claude"])
        self.assertEqual(migration_targets("youtube-music-playlist"), ["agents", "claude"])
        self.assertEqual(migration_targets("brainstorming"), ["agents", "claude"])

    def test_unknown_raises(self):
        with self.assertRaises(ValueError):
            migration_targets("brand-new-skill")


class CatalogTest(unittest.TestCase):
    _SECTION5 = """\
## 5. 独自（1件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/aaa` | alpha | when a |
"""

    def test_upsert_inserts_alphabetically_after_aaa(self):
        md = upsert_catalog_row(self._SECTION5, 5, "mmm", "middle", "when m")
        rows = [line for line in md.splitlines() if line.startswith("| `/")]
        self.assertEqual(len(rows), 2)
        self.assertIn("/aaa", rows[0])
        self.assertIn("/mmm", rows[1])

    def test_upsert_rejects_em_dash_when(self):
        with self.assertRaises(ValueError):
            upsert_catalog_row(self._SECTION5, 5, "bbb", "beta", "—")

    def test_recount_updates_section_heading(self):
        md = """\
## 5. 独自（1件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/aaa` | a | u1 |
| `/bbb` | b | u2 |
"""
        out = recount_section_headings(md)
        self.assertIn("## 5. 独自（2件）", out)

    def test_recount_syncs_toc_label_and_anchor_when_count_changes(self):
        md = """\
## 目次

5. [独自の開発系スキル（14件）](#5-独自の開発系スキル14件)

---

## 5. 独自の開発系スキル（14件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/aaa` | a | u1 |
| `/bbb` | b | u2 |
| `/ccc` | c | u3 |
"""
        out = recount_section_headings(md)
        self.assertIn("## 5. 独自の開発系スキル（3件）", out)
        self.assertIn("[独自の開発系スキル（3件）](#5-独自の開発系スキル3件)", out)
        self.assertNotIn("独自の開発系スキル14件", out)
        self.assertNotIn("独自の開発系スキル（14件）", out)

    def test_recount_skips_reference_rows_with_em_dash_when(self):
        md = """\
## 9. マーケ（2件）

| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/real` | r | usage |
| `/ref-only` | 参照 | — |
"""
        out = recount_section_headings(md)
        self.assertIn("## 9. マーケ（1件）", out)

    def test_missing_manifest_names(self):
        md = """\
| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/aaa` | a | u |
"""
        self.assertEqual(missing_manifest_names(["aaa", "zzz"], md), ["zzz"])

    def test_manual_only_command_counts_as_present(self):
        md = """\
| コマンド | 説明 | 使いどころ |
|----------|------|-----------|
| `/name`（手動のみ） | n | u |
"""
        self.assertEqual(missing_manifest_names(["name", "other"], md), ["other"])


if __name__ == "__main__":
    unittest.main()
