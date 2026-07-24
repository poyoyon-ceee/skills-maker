# Canonical Documentation Structure

Use this reference when deciding which files should exist and where merged information belongs.

## Core rule

Create the smallest set that accurately represents the repository. A filename is not a requirement. If a section in an existing canonical file is enough, do not create another file.

## `README.md`: project entry point

Keep it concise and evidence-based. Include only applicable sections:

- project name and one-sentence purpose;
- verified current status; use `要確認` for unverified operational status;
- primary users or use case only when supported by evidence;
- major capabilities;
- screenshot only when a current image already exists or the user requests one;
- prerequisites and supported environment;
- shortest verified setup, run, or usage path;
- important inputs and outputs;
- key limitations or known issues;
- brief repository map;
- links to existing canonical docs.

Avoid detailed architecture, exhaustive specifications, long change logs, AI instructions, speculative roadmaps, and duplicated content.

## `docs/index.md`: documentation hub

List each existing canonical document with:

- its purpose;
- the kind of question it answers;
- whether it is authoritative for that topic.

Do not duplicate the documents' contents. Do not link to nonexistent files.

## Conditional canonical documents

### `docs/spec.md`

Create or retain when functional behavior needs more space than README:

- features and user-visible behavior;
- inputs, outputs, validation, and failure behavior;
- interfaces, data formats, and constraints;
- explicitly unresolved requirements marked `要確認`.

### `docs/architecture.md`

Create or retain when structural knowledge is substantial:

- components and responsibilities;
- important dependencies and boundaries;
- data or control flow;
- persistence and external integrations;
- current design decisions and constraints.

Describe the implemented architecture, not an aspirational redesign.

### `docs/development.md`

Create or retain when contributor instructions are nontrivial:

- verified local setup;
- build, test, lint, and release commands;
- environment variables without secret values;
- repository-specific conventions and workflows.

Do not copy generic Git or language tutorials.

### `docs/changelog.md`

Retain when the project already maintains a changelog or users need a curated history. Preserve the existing format when sound. Do not reconstruct a speculative history from commit messages.

## AI-specific folders

Folders such as `.claude`, `.cursor`, `.codex`, `.agent`, and `.agents` may contain:

- tool-specific configuration and metadata;
- reusable skills or commands;
- concise pointers to `README.md` and `docs/index.md`.

Move project purpose, behavior, architecture, setup, and operational knowledge to canonical docs. Do not assume every tool follows pointers automatically; keep canonical paths explicit.

## Files that usually indicate duplication

Review names such as:

- `spec-old.md`, `spec-new.md`, `spec-final.md`, `spec-v2.md`;
- `latest.md`, `summary.md`, `analysis.md`, `report.md`;
- AI-generated handoff, audit, plan, or completion reports;
- both `docs/README.md` and `docs/index.md`;
- repeated architecture or setup instructions in multiple AI folders.

The filename alone never justifies deletion. Preserve unique current information first.
