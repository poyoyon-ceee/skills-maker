---
name: webapp-testing
description: >-
  Tests local web applications via Cursor browser MCP or Playwright scripts.
  Use when verifying frontend UI, debugging browser behavior, e2e testing,
  localhost testing, capturing screenshots, or when the user says "test my app"
  or "check the UI".
---

# Web Application Testing

Adapted from [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/webapp-testing) for Cursor.

## Test Layers

| Layer | Tool | When |
|-------|------|------|
| Unit / component | Vitest, Jest, pytest | Logic, utilities, isolated components |
| Browser E2E (Cursor) | `cursor-ide-browser` MCP | Interactive UI verification in IDE |
| Browser E2E (scripted) | Playwright Python + `scripts/with_server.py` | Repeatable automation, CI |

Use the right layer. Don't use browser E2E for logic that unit tests cover.

## Decision Tree

```
User task → Unit-testable logic?
    ├─ Yes → Write Vitest/Jest test (use test-driven-development skill)
    │
    └─ No (UI/browser) → Is it static HTML?
        ├─ Yes → Read HTML file directly for selectors
        │         └─ Cursor browser or Playwright with file:// URL
        │
        └─ No (dynamic app) → Server running?
            ├─ No → Start dev server, then test
            │        python scripts/with_server.py --help  (Playwright path)
            │        OR npm run dev / npm run preview (Cursor browser path)
            │
            └─ Yes → Reconnaissance-then-action (below)
```

## Cursor Browser MCP Workflow

Use when testing in Cursor with the built-in browser tools.

**Lock/unlock order:**
1. `browser_navigate` to target URL
2. `browser_lock` with action `lock`
3. Interact (`browser_snapshot`, `browser_click`, `browser_type`, etc.)
4. `browser_lock` with action `unlock` when done

**If a tab already exists:** `browser_lock` first, then interact.

### Reconnaissance-Then-Action

1. **Navigate** — `browser_navigate` to `http://localhost:<port>`
2. **Snapshot** — `browser_snapshot` to get page structure and element refs
3. **Screenshot** (optional) — `browser_take_screenshot` for visual verification
4. **Act** — `browser_click`, `browser_type`, `browser_fill` using refs from snapshot
5. **Verify** — snapshot or screenshot again; check console via `browser_cdp` if needed

**Don't** click before snapshot on dynamic apps — wait for the page to settle.

### Common Dev Server Commands

| Project | Start | Preview (production build) |
|---------|-------|------------------------------|
| Vite | `npm run dev` (default :5173) | `npm run build && npm run preview` |
| Next.js | `npm run dev` (:3000) | `npm run build && npm start` |

**Offline projects:** Test against `localhost` only. No external CDN or API calls in test paths.

**dist sync projects:** If the repo syncs to `dist/`, test the same target the user ships (dev source vs `dist/` preview) — ask or check `.cursor/rules/dist-folder-sync.md`.

## Playwright Scripted Workflow

For repeatable Python automation. Requires `playwright` installed (`pip install playwright && playwright install chromium`).

**Helper script:** `scripts/with_server.py` — starts server(s), waits for port, runs your script, tears down.

**Always run `--help` first.** Treat scripts as black boxes; don't read source unless customization is necessary.

### Single server

```bash
python scripts/with_server.py --server "npm run dev" --port 5173 -- python your_test.py
```

### Playwright script template

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:5173')
    page.wait_for_load_state('networkidle')
    # ... automation logic
    browser.close()
```

## Common Pitfalls

- Inspecting DOM before JS finishes on dynamic apps → wait for `networkidle` or use snapshot after load
- Testing dev build when production ships from `dist/` → test the correct build target
- Using E2E for pure logic → use unit tests instead
- Forgetting `browser_unlock` after Cursor browser testing

## Best Practices

- Descriptive selectors: `text=`, `role=`, CSS, IDs
- Screenshot before and after critical actions for evidence
- Close browser / unlock when done
- Add `page.wait_for_selector()` or equivalent waits for async UI
