"""Pure helpers for incoming sync target validation and legacy install paths."""

import re

_CANONICAL_ORDER = ("agents", "cursor", "claude")
_VALID_TOKENS = frozenset(_CANONICAL_ORDER)

_BOX_TARGETS: dict[str, list[str]] = {
    "agents-claude": ["agents", "claude"],
    "agents-only": ["agents"],
    "claude-only": ["claude"],
    "cursor-only": ["cursor"],
}


def targets_for_box(box: str) -> list[str]:
    try:
        return list(_BOX_TARGETS[box])
    except KeyError as exc:
        raise ValueError(f"unknown box: {box}") from exc


def validate_targets(targets: list[str]) -> list[str]:
    if not targets:
        raise ValueError("targets must not be empty")
    unknown = [t for t in targets if t not in _VALID_TOKENS]
    if unknown:
        raise ValueError(f"unknown target token: {unknown[0]}")
    if "agents" in targets and "cursor" in targets:
        raise ValueError("agents and cursor cannot be combined")
    order = {token: index for index, token in enumerate(_CANONICAL_ORDER)}
    return sorted(targets, key=lambda t: order[t])


def legacy_install_target(targets: list[str], name: str) -> str:
    validated = validate_targets(targets)
    if "cursor" in validated:
        return f"~/.cursor/skills/{name}/"
    if "agents" in validated:
        return f"~/.agents/skills/{name}/"
    return f"~/.claude/skills/{name}/"


_CURSOR_ONLY = frozenset({"skill-creator"})
_CURSOR_CLAUDE = frozenset({"chat-handoff", "promote-skill"})
_AGENTS_ONLY = frozenset(
    {
        "docx",
        "pdf",
        "pptx",
        "xlsx",
        "requesting-code-review",
        "receiving-code-review",
        "using-git-worktrees",
        "model-router-gpt",
    }
)
_AGENTS_CLAUDE = frozenset(
    {
        "00",
        "app-tech-inventory",
        "brainstorming",
        "canvas-design",
        "content-research-writer",
        "debug-allrun",
        "dispatching-parallel-agents",
        "doc-coauthoring",
        "doc-maint",
        "edit-article",
        "executing-plans",
        "finishing-a-development-branch",
        "frontend-design",
        "git-guardrails",
        "github-make-sync",
        "git-in-clone",
        "grill-me",
        "gws-docs",
        "gws-drive",
        "gws-sheets",
        "improve-codebase-architecture",
        "json-canvas",
        "new-project",
        "notebooklm",
        "obsidian-markdown",
        "obsidian-vault",
        "playbook-app-improvement",
        "playbook-article-production",
        "playbook-document-data",
        "playbook-fable5-7day",
        "playbook-mini-webapp",
        "playbook-research-assets",
        "project-foundation",
        "react-best-practices",
        "route-playbook",
        "session-recap",
        "subagent-driven-development",
        "systematic-debugging",
        "test-driven-development",
        "theme-factory",
        "to-issues",
        "to-knowledge",
        "to-prd",
        "using-superpowers",
        "verification-before-completion",
        "webapp-testing",
        "web-artifacts-builder",
        "writing-plans",
        "writing-skills",
        "x-reader",
        "youtube-music-playlist",
    }
)


def migration_targets(name: str) -> list[str]:
    if name in _CURSOR_ONLY:
        return validate_targets(["cursor"])
    if name in _CURSOR_CLAUDE:
        return validate_targets(["cursor", "claude"])
    if name in _AGENTS_ONLY:
        return validate_targets(["agents"])
    if name in _AGENTS_CLAUDE:
        return validate_targets(["agents", "claude"])
    raise ValueError(f"unknown skill for migration: {name}")


_SECTION_HEADING = re.compile(r"^(## (\d+)\.\s+)(.+?)（(\d+)件）(.*)$")
_COMMAND_IN_CELL = re.compile(r"`/([^`]+)`")


def _command_name_from_cell(cmd_cell: str) -> str | None:
    m = _COMMAND_IN_CELL.search(cmd_cell)
    if not m:
        return None
    return m.group(1).strip()


def _is_catalog_table_header(line: str) -> bool:
    return line.strip().startswith("|") and "コマンド" in line and "使いどころ" in line


def _is_table_separator(line: str) -> bool:
    s = line.strip()
    return s.startswith("|") and set(s.replace("|", "").replace("-", "").replace(":", "").strip()) == set()


def _format_catalog_row(command: str, summary: str, when: str, manual_only: bool = False) -> str:
    cmd = command.lstrip("/")
    suffix = "（手動のみ）" if manual_only else ""
    return f"| `/{cmd}`{suffix} | {summary} | {when} |"


def _section_bounds(lines: list[str], section: int) -> tuple[int, int]:
    start = None
    for i, line in enumerate(lines):
        if re.match(rf"^## {section}\.", line):
            start = i
            break
    if start is None:
        raise ValueError(f"section not found: {section}")
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if re.match(r"^## \d+\.", lines[j]):
            end = j
            break
    return start, end


def _count_section_rows(lines: list[str], start: int, end: int) -> int:
    count = 0
    in_table = False
    for line in lines[start + 1 : end]:
        if line.startswith("### "):
            in_table = False
            continue
        if _is_catalog_table_header(line):
            in_table = False
            continue
        if _is_table_separator(line):
            in_table = True
            continue
        if not in_table or not line.strip().startswith("|"):
            if not line.strip().startswith("|"):
                in_table = False
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3:
            continue
        if cells[2].strip() == "—":
            continue
        count += 1
    return count


def _replace_section_count(line: str, count: int) -> str:
    m = _SECTION_HEADING.match(line)
    if not m:
        return line
    return f"{m.group(1)}{m.group(3)}（{count}件）{m.group(5)}"


def _sync_section_count_references(
    markdown: str, section_no: int, title: str, count: int
) -> str:
    text = re.sub(
        re.escape(title) + r"（\d+件）",
        f"{title}（{count}件）",
        markdown,
    )
    text = re.sub(
        rf"(#{section_no}-[^\s\)]*?)\d+件",
        rf"\g<1>{count}件",
        text,
    )
    return text


def recount_section_headings(markdown: str) -> str:
    lines = markdown.splitlines()
    trailing_newline = markdown.endswith("\n")
    sync_jobs: list[tuple[int, str, int]] = []
    i = 0
    while i < len(lines):
        m = _SECTION_HEADING.match(lines[i])
        if not m:
            i += 1
            continue
        section_no = int(m.group(2))
        title = m.group(3)
        start, end = _section_bounds(lines, section_no)
        count = _count_section_rows(lines, start, end)
        lines[i] = _replace_section_count(lines[i], count)
        sync_jobs.append((section_no, title, count))
        i = end
    text = "\n".join(lines) + ("\n" if trailing_newline else "")
    for section_no, title, count in sync_jobs:
        text = _sync_section_count_references(text, section_no, title, count)
    return text


def upsert_catalog_row(
    markdown: str,
    section: int,
    command: str,
    summary: str,
    when: str,
) -> str:
    if when.strip() == "—":
        raise ValueError("when must not be em dash")
    cmd = command.lstrip("/")
    lines = markdown.splitlines()
    start, end = _section_bounds(lines, section)

    table_start = None
    table_end = None
    for i in range(start + 1, end):
        if _is_catalog_table_header(lines[i]):
            table_start = i
            table_end = i + 1
            if table_end < end and _is_table_separator(lines[table_end]):
                table_end += 1
            while table_end < end and lines[table_end].strip().startswith("|"):
                if _is_table_separator(lines[table_end]):
                    table_end += 1
                    continue
                table_end += 1
            break

    if table_start is None:
        raise ValueError(f"no catalog table in section {section}")

    data_start = table_start + 1
    while data_start < table_end and not lines[data_start].strip().startswith("| `/"):
        if _is_table_separator(lines[data_start]):
            data_start += 1
        else:
            data_start += 1

    row_lines: list[str] = []
    row_indices: list[int] = []
    for i in range(data_start, table_end):
        if not lines[i].strip().startswith("|"):
            break
        if _is_table_separator(lines[i]):
            continue
        name = _command_name_from_cell(lines[i].split("|", 2)[1] if "|" in lines[i] else lines[i])
        if name is None:
            continue
        row_lines.append(lines[i])
        row_indices.append(i)

    manual_only = False
    new_row = _format_catalog_row(cmd, summary, when, manual_only)
    replaced = False
    for idx, row in zip(row_indices, row_lines):
        existing = _command_name_from_cell(row)
        if existing == cmd:
            lines[idx] = new_row
            replaced = True
            break

    if not replaced:
        insert_at = data_start
        for idx, row in zip(row_indices, row_lines):
            existing = _command_name_from_cell(row)
            if existing and existing > cmd:
                insert_at = idx
                break
            insert_at = idx + 1
        lines.insert(insert_at, new_row)

    start, end = _section_bounds(lines, section)
    count = _count_section_rows(lines, start, end)
    heading_match = _SECTION_HEADING.match(lines[start])
    if heading_match is None:
        raise ValueError(f"section heading missing count: {section}")
    title = heading_match.group(3)
    lines[start] = _replace_section_count(lines[start], count)
    text = "\n".join(lines) + ("\n" if markdown.endswith("\n") else "")
    return _sync_section_count_references(text, section, title, count)


def missing_manifest_names(manifest_names: list[str], markdown: str) -> list[str]:
    present: set[str] = set()
    for line in markdown.splitlines():
        if not line.strip().startswith("|"):
            continue
        if _is_catalog_table_header(line) or _is_table_separator(line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells:
            continue
        name = _command_name_from_cell(cells[0])
        if name:
            present.add(name)
    return sorted(n for n in manifest_names if n not in present)
