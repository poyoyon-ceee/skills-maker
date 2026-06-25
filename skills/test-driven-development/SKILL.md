---
name: test-driven-development
description: >-
  Enforces RED-GREEN-REFACTOR test-driven development before implementation code.
  Use when implementing features, bug fixes, refactoring, or behavior changes;
  when the user mentions TDD, tests first, or failing tests; or before writing
  production code for any behavioral change.
---

# Test-Driven Development (TDD)

Adapted from [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/test-driven-development) for Cursor.

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Always:**
- New features
- Bug fixes
- Refactoring
- Behavior changes

**Exceptions (ask the user first):**
- Throwaway prototypes
- Generated code
- Configuration-only changes

Thinking "skip TDD just this once"? Stop. That's rationalization.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

## Red-Green-Refactor

### RED — Write Failing Test

Write one minimal test showing what should happen.

**Requirements:**
- One behavior per test
- Clear name describing behavior
- Real code (no mocks unless unavoidable)

### Verify RED — Watch It Fail (MANDATORY)

Run the single test file or case. Never skip this step.

**Project test runners (use what the repo uses):**

| Stack | Command |
|-------|---------|
| Vitest (JS/TS) | `npm test -- path/to/test.test.ts` or `npx vitest run path/to/test.test.ts` |
| Jest | `npm test -- path/to/test.test.ts` |
| pytest | `pytest tests/path/test.py::test_name -v` |
| Rust | `cargo test test_name` |

Confirm:
- Test **fails** (not errors)
- Failure message is expected
- Fails because feature is missing (not typos)

**Test passes?** You're testing existing behavior. Fix the test.

**Test errors?** Fix the error, re-run until it fails correctly.

### GREEN — Minimal Code

Write the simplest code to pass the test. Don't add features, refactor other code, or "improve" beyond the test.

### Verify GREEN — Watch It Pass (MANDATORY)

Run the same test command. Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

**Test fails?** Fix code, not test.

**Other tests fail?** Fix now.

### REFACTOR — Clean Up

After green only: remove duplication, improve names, extract helpers. Keep tests green. Don't add behavior.

### Repeat

Next failing test for next behavior.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

## Red Flags — STOP and Start Over

- Code before test
- Test after implementation
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "Keep as reference" or "adapt existing code"

**All of these mean: Delete code. Start over with TDD.**

## Bug Fix Workflow

1. **RED** — Write failing test reproducing the bug
2. **Verify RED** — Watch it fail for the expected reason
3. **GREEN** — Minimal fix
4. **Verify GREEN** — All tests pass
5. **REFACTOR** — Clean up if needed

Never fix bugs without a test.

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask the user. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Testing Anti-Patterns

When adding mocks or test utilities, read [reference.md](reference.md) to avoid:
- Testing mock behavior instead of real behavior
- Adding test-only methods to production classes
- Mocking without understanding dependencies

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without the user's permission.
