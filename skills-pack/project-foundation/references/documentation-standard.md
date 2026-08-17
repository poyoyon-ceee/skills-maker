# Documentation standard

Smallest evidence-based set. A filename is not a requirement.

## Required core

### Root `README.md`

Required in every project.

- name and purpose
- verified current status
- major capabilities
- shortest setup / run path
- important constraints
- repository map
- links to detailed docs

README is the entry point. Do not copy detailed specs, long designs, or tool-specific instructions into it.

### `docs/index.md`

Required only when `docs/` already has at least one canonical document.

- document name
- what it is canonical for
- status
- when to read it

Skip it for tiny projects that fit in README alone.

## Conditional documents

Create only when the content exists.

```text
docs/
├─ index.md
├─ spec.md
├─ architecture.md
├─ development.md
├─ design/
│  └─ <topic>.md
├─ plans/
│  └─ <topic>.md
└─ decisions/
   └─ <decision>.md
```

- `spec.md`: implemented behavior that does not fit in README
- `architecture.md`: current components, boundaries, important data flow
- `development.md`: non-obvious dev / test / build steps
- `design/`: unimplemented or upcoming design
- `plans/`: approved implementation plans
- `decisions/`: decisions worth keeping the rationale for

`CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, and `LICENSE` only when the project is published, distributed, or team-operated that way.

## AI entry

For AI-maintained projects, root `AGENTS.md` is recommended:

- what to read before working
- plan vs implementation boundary
- git and uncommitted changes
- when commit / push / publish is allowed
- documentation hub for the modules in scope

`.cursor/rules/`, `CLAUDE.md`, and `.codex/` hold tool-specific settings and short pointers to canonical docs. Do not duplicate project knowledge there.

## Hidem profile (optional)

Add only when the user chooses it:

- `PROJECT.md` — purpose, scope, non-goals, long-term principles
- `.project_rules/MASTER_PROTOCOL.md` — branch rules, implementation gates, working conventions

These are an extra layer pointed to from README and AGENTS. They are not the general standard.

## Tech manifests

Generate only when the stack needs them (`package.json`, `Cargo.toml`, `pyproject.toml`, `*.csproj`). Do not invent a manifest just to look organized.

## Document status labels

Use in `docs/index.md` when useful: `current`, `approved-design`, `draft`, `superseded`, `historical`. Labels only — do not create status folders.

## Forbidden

- `spec-final.md`, `spec-new.md`, `latest.md`, and other names that hide the canonical file
- empty placeholders
- copying the same content into README, PROJECT, and AGENTS
- project knowledge that lives only in AI-specific folders
- describing unimplemented features as shipped in README
- a `package.json` with no real dependencies or scripts
- a new audit report file on every pass
- overwriting existing docs with a template without checking
