---
name: debug-allrun
description: デバッガ付きで起動し、データ破損・非同期レース・分岐ミスの隠れバグを探索。検出したバグを自動修正し、バグレポと修正レポを報告する。/debug-allrun で使う。
disable-model-invocation: true
---

# Debug All Run

**Goal:** Launch with a real debugger (F5 equivalent), actively hunt **hidden bugs** that normal dev runs miss, fix them, and deliver two reports plus a final summary.

The agent cannot press F5 in the IDE UI. Use debugger APIs (DAP / CDP / debugpy) or attach to an inspectable process per stack below.

Do **not** treat "no crash for 10 seconds" as success. Success means critical paths were exercised and inspected without confirmed bugs.

## Three hidden bug types (hunt targets)

Tag every finding with one of:

| Tag | Name | What to catch | Where to observe |
|-----|------|---------------|------------------|
| `silent-data` | 裏でデータが壊れている | `null` / `undefined` / empty payload saved or passed on; swallowed errors in `catch` | DB writes, API POST bodies, state setters, serializers, `localStorage` |
| `race` | タイミングでたまに失敗 | Data used before async completes; stale closure; missing `await` | `fetch` / `axios`, `await`, `.then`, `useEffect`, event handlers after async |
| `wrong-branch` | 分岐ロジックのミス | Wrong `if` / `switch` taken; bad predicate; off-by-one bounds | Condition lines, early returns, ternary routing |

Also record `crash` (uncaught exception / non-zero exit) when it appears—but prioritize the three hidden types.

## Prerequisites

1. Workspace root is the project root
2. `.vscode/launch.json` exists (preferred) or debug entry is inferable
3. Runtime installed (`node`, `python`, `dotnet`, etc.)
4. For UI flows: dev server URL known; use **webapp-testing** / browser MCP for driving the UI while debugging backend or via CDP

If `launch.json` is missing, offer a minimal config or ask which config equals F5 for this project.

**Expectation sources** (use in priority order—do not invent business rules):

1. Existing tests (unit / integration / e2e)
2. Types, schemas, Zod/Pydantic models, DB constraints
3. Comments, README, obvious invariants (`id` must exist, array non-empty before save)
4. Ask the user when still ambiguous

## Workflow

```
Task Progress:
- [ ] Phase A: Resolve launch config and debugger strategy
- [ ] Phase B: Map critical paths and design observation points
- [ ] Phase C: Launch debugger and run scenarios
- [ ] Phase D: Inspect, record bugs, fix, re-verify (loop)
- [ ] Phase E: Deliver bug report + fix report + summary
```

### Phase A: Resolve launch config and debugger strategy

Read `.vscode/launch.json`:

- Pick config (`AskQuestion` if multiple `launch` configs)
- Resolve `${workspaceFolder}`, `cwd`, `env`, `args`
- Run `preLaunchTask` from `.vscode/tasks.json` if required

Choose debugger control method by `type`:

| launch `type` | Control method |
|---------------|----------------|
| `node` | Start with `node --inspect-brk=9229` (or port from config) → CDP via script or evaluate; or use VS Code debugpy-style attach if configured |
| `python` | `debugpy` listen / launch; set breakpoints by line; `evaluate` expressions at stop |
| `dotnet` | `dotnet run` with debugger attach, or test runner with debug; inspect locals at breakpoint |
| Browser / Vite / Next | Start dev server + **browser MCP** + CDP (`Runtime.evaluate`, network, console); backend via Node/Python attach in parallel if full-stack |

**Minimum viable without custom scripts:** For Node, run inspect process in background, use a short helper script or CDP WebSocket to set breakpoints, continue, and read scope. For Python, use `debugpy` adapter pattern. If debugger control is blocked, fall back to **instrumented logging at observation lines** only for that run—and note reduced confidence in the report.

Kill prior debug processes before restart (port conflicts).

### Phase B: Map critical paths and design observation points

1. Read entry points (main, routes, handlers, stores, DB layer)
2. List **scenarios** to exercise (CLI args, API calls, UI clicks—confirm with user if unclear)
3. For each scenario, place **observation points** (breakpoints or conditional stops):

**silent-data** — stop immediately before:

- `insert` / `update` / `save` / `commit`
- `fetch(POST…)` / `axios.post` / `mutate`
- `setState` / `dispatch` with payload built from user input or API

At stop: evaluate payload. Flag if `null`, `undefined`, `{}` when data required, or required fields missing.

**race** — stop at:

- Line **before** first use of async result
- Line **after** `await` / `.then` callback entry
- `useEffect` body that reads async-derived state

At stop: check if dependency is still pending / undefined while next line uses it. Use step-over to confirm order. Optionally throttle network (CDP `Network.emulateNetworkConditions`) to force slow responses.

**wrong-branch** — stop at:

- `if` / `else if` / `switch` / ternary condition line
- Function return that picks between two behaviors

At stop: log predicate inputs and which branch will run. Compare to expectation from tests/types/comments.

Do not breakpoint every line—only high-value points per path. Skip noise (framework boilerplate) unless suspicious.

Maintain a running **bug ledger** (in memory until Phase E):

```
BUG-001 | silent-data | file:line | observed | expected | scenario
```

### Phase C: Launch debugger and run scenarios

1. Start debugger per Phase A
2. Set breakpoints / conditional breakpoints at observation points from Phase B
3. Execute each scenario:
   - CLI: run with configured `args`
   - API: `curl` / HTTP client against local server
   - UI: browser MCP navigate → click → fill forms (read **webapp-testing** skill if needed)
4. On each stop: capture locals, call stack, and whether invariant holds
5. Continue / step as needed; do not stop on every line unless investigating a specific suspicion

Monitor stderr and debug console for uncaught errors in parallel.

### Phase D: Inspect, record, fix, re-verify

For each confirmed bug:

1. Add entry to bug ledger with tag, repro steps, evidence (variable snapshot)
2. Classify fixability:
   - Code bug → minimal fix
   - Missing dep / config → fix or ask user
   - Spec unclear → ask user; do not guess business logic
3. Apply **minimal fix** (match project style; no unrelated refactor)
4. Re-run **same scenario** from Phase C to verify
5. If verified, mark bug `fixed` in ledger; else iterate

**Loop limits:**

- Max **8** fix iterations per skill run; then report and ask to continue
- Same bug ID unfixed after **2** attempts → mark `blocked`, explain why
- Never commit unless user explicitly asks

**Fix quality rules:**

- Prefer root cause over suppression (no empty `catch`, no `@ts-ignore` to hide)
- For `race`: prefer `await`, proper loading state, cancellation, or guard clauses
- For `silent-data`: validate before persist; surface errors to user/log
- For `wrong-branch`: fix predicate or data feeding the branch

### Phase E: Deliver reports

Always output **three sections** in this order:

---

#### 1. バグレポ（発見）

```markdown
# バグレポ

| ID | 分類 | 場所 | シナリオ | 観測 | 期待 | 状態 |
|----|------|------|----------|------|------|------|
| BUG-001 | silent-data | path:line | ... | ... | ... | fixed / open / blocked |

## 詳細
### BUG-001
- 分類: ...
- 再現手順: ...
- 証拠: (変数スナップショット / スタック)
- 備考: ...
```

---

#### 2. バグ取りレポ（修正）

```markdown
# バグ取りレポ

| バグ ID | 変更ファイル | 修正概要 | 再検証 |
|---------|--------------|----------|--------|
| BUG-001 | path | ... | OK / 未実施 |

## 変更サマリ
- ...
```

If no bugs found, state that explicitly and list what paths were inspected.

---

#### 3. 終了報告

```markdown
# 終了報告

- **起動構成**: (launch config name + effective debug command)
- **実行シナリオ**: ...
- **観測点数**: ...
- **発見バグ数**: N (silent-data: a, race: b, wrong-branch: c, crash: d)
- **修正済み**: ...
- **未解決 / 要確認**: ...
- **デバッグ手段**: (CDP / debugpy / attach / fallback logging)
- **残リスク**: (flaky timing, untested paths, manual QA needed)
```

---

## Error handling

| Situation | Action |
|-----------|--------|
| No `launch.json` | Draft minimal config or ask user for F5 equivalent |
| Cannot attach debugger | Fallback logging at observation points; note lower confidence |
| Port in use | Kill prior debug/dev process or change port |
| UI scenario unknown | Ask user which flow to exercise |
| Flaky race | Run scenario ≥2 times with network throttle; mark flaky if intermittent |
| Needs secrets / prod data | Stop; list in 要確認 |

## Constraints

- NEVER update git config (user/global)
- NEVER commit or push unless the user explicitly asks
- NEVER invent API keys, env values, or business rules
- NEVER delete existing comments or debug prints
- Run only in the user's workspace root
- Read **webapp-testing** when driving browser UI during scenarios
