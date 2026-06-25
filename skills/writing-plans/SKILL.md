---
name: writing-plans
description: >-
  Creates bite-sized implementation plans with exact file paths, code snippets,
  and verification steps before coding begins. Use when the user has a spec or
  multi-step task, asks for an implementation plan, or before touching code for
  non-trivial features.
---

# Writing Plans

Adapted from [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/writing-plans) for Cursor.

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for the codebase. Document everything they need: which files to touch, code, testing, docs to check, how to verify. Give the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume a skilled developer who knows almost nothing about this toolset or problem domain.

**Announce at start:** "writing-plans スキルを使って実装計画を作成します。"

## Save Location

| Scope | Path |
|-------|------|
| Default | `docs/plans/YYYY-MM-DD-<feature-slug>.md` |
| Project override | If `.cursor/templates/implementation-plan-template.md` exists, align with that structure |
| User override | User-specified path wins |

Create the `docs/plans/` directory if it doesn't exist.

## Scope Check

If the spec covers multiple independent subsystems, break into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure (Before Tasks)

Map files to create or modify and what each one is responsible for:

- Clear boundaries and well-defined interfaces
- Prefer smaller, focused files
- Files that change together should live together
- In existing codebases, follow established patterns

**Project-specific:** If the repo has a `dist/` sync rule (see `.cursor/rules/dist-folder-sync.md`), include dist sync steps in tasks that change frontend assets.

## Task Right-Sizing

A task is the smallest unit with its own test cycle worth a reviewer's gate. Fold setup, config, scaffolding, and docs into the task whose deliverable needs them. Split only where a reviewer could reject one task while approving its neighbor.

## Bite-Sized Granularity

**Each step is one action (2–5 minutes):**
- "Write the failing test" — step
- "Run it to verify it fails" — step
- "Implement minimal code" — step
- "Run tests and verify pass" — step
- "Commit" — step (only when user requests commits)

## Plan Document Header

Every plan MUST start with this header:

```markdown
# [Feature Name] Implementation Plan

> **For Cursor agent:** Implement task-by-task. Use TDD (test-driven-development skill).
> Track progress with checkbox (`- [ ]`) syntax.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2–3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[Project-wide requirements — version floors, offline rules, naming conventions,
platform requirements — one line each with exact values from the spec.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts:123-145`
- Test: `tests/exact/path/to/test.ts`

**Interfaces:**
- Consumes: [what this task uses — exact signatures]
- Produces: [what later tasks rely on — exact names and types]

- [ ] **Step 1: Write the failing test**

```typescript
test('specific behavior', () => {
  expect(function(input)).toBe(expected);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx vitest run tests/path/test.ts`
Expected: FAIL with "[reason]"

- [ ] **Step 3: Write minimal implementation**

```typescript
export function functionName(input: Type): ReturnType {
  return expected;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx vitest run tests/path/test.ts`
Expected: PASS

- [ ] **Step 5: Sync dist** (if project requires dist sync)

- [ ] **Step 6: Commit** (only when user requests)
````

## No Placeholders

Plan failures — never write these:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" without showing how
- "Write tests for the above" without actual test code
- "Similar to Task N" (repeat the code)
- References to types/functions not defined in any task

## Remember

- Exact file paths always
- Complete code in every step that changes code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits (when user asks)

## Self-Review

After writing the plan:

1. **Spec coverage:** Each requirement maps to a task. List gaps.
2. **Placeholder scan:** Fix any vague steps.
3. **Type consistency:** Signatures match across tasks.

Fix issues inline before presenting the plan.

## Execution Handoff

After saving the plan, offer execution choice:

**"計画を `docs/plans/YYYY-MM-DD-<feature>.md` に保存しました。実行方法は2つ:**

**1. インライン実行（推奨）** — このセッションでタスクを順に実行、チェックポイントで確認

**2. サブエージェント実行** — Task ツールでタスクごとにサブエージェントを起動、タスク間でレビュー

**どちらにしますか？"**

**If subagent chosen:**
- Launch one `generalPurpose` or appropriate subagent per task
- Review output between tasks before proceeding

**If inline chosen:**
- Execute tasks sequentially
- Pause at task boundaries for user confirmation on large changes
