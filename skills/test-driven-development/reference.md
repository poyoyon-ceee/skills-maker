# Testing Anti-Patterns

Load when writing or changing tests, adding mocks, or tempted to add test-only methods to production code.

Adapted from [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/test-driven-development).

## Core Principle

Tests must verify real behavior, not mock behavior. Mocks isolate; they are not the thing being tested.

## Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production classes
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

```typescript
// BAD: Testing that the mock exists
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});

// GOOD: Test real component or don't mock it
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});
```

**Gate:** Before asserting on any mock element, ask: "Am I testing real behavior or mock existence?"

## Anti-Pattern 2: Test-Only Methods in Production

```typescript
// BAD: destroy() only used in tests
class Session {
  async destroy() { /* cleanup */ }
}

// GOOD: Test utilities handle cleanup
export async function cleanupSession(session: Session) { /* ... */ }
```

**Gate:** Before adding any method to a production class, ask: "Is this only used by tests?"

## Anti-Pattern 3: Mocking Without Understanding

```typescript
// BAD: Mock prevents side effect the test depends on
vi.mock('ToolCatalog', () => ({
  discoverAndCacheTools: vi.fn().mockResolvedValue(undefined)
}));

// GOOD: Mock at the correct level (slow/external only)
vi.mock('MCPServerManager');
```

**Gate:** Before mocking, ask what side effects the real method has and whether this test depends on them.

## Anti-Pattern 4: Incomplete Mocks

Partial mocks hide structural assumptions. Mirror the complete real API response schema.

## Anti-Pattern 5: Tests as Afterthought

TDD cycle: failing test → implement → refactor → then claim complete.

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Assert on mock elements | Test real component or unmock it |
| Test-only methods in production | Move to test utilities |
| Mock without understanding | Understand dependencies first, mock minimally |
| Incomplete mocks | Mirror real API completely |
| Tests as afterthought | TDD — tests first |
| Over-complex mocks | Consider integration tests |

## Red Flags

- Assertion checks for `*-mock` test IDs
- Methods only called in test files
- Mock setup is >50% of test
- Test fails when you remove mock
- Can't explain why mock is needed
- Mocking "just to be safe"

## Common TDD Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Unverified code is technical debt. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "TDD will slow me down" | TDD is faster than debugging in production. |
