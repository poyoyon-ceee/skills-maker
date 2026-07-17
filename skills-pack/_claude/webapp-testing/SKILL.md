---
name: webapp-testing
description: >-
  Tests local web applications via Claude Code browser tools or Playwright
  scripts. Use when verifying frontend UI, debugging browser behavior, e2e
  testing, localhost testing, capturing screenshots, or when the user says
  "test my app" or "check the UI".
---

# Web Application Testing

Adapted from [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/webapp-testing) for Claude Code.

## Test Layers

| Layer | Tool | When |
|-------|------|------|
| Unit / component | Vitest, Jest, pytest | Logic, utilities, isolated components |
| Browser E2E (Claude Code) | Claude Preview tools (`preview_*`) | Interactive UI verification in session |
| Browser E2E (scripted) | Playwright Python + `scripts/with_server.py` | Repeatable automation, CI |

Use the right layer. Don't use browser E2E for logic that unit tests cover.

## Decision Tree

```
User task → Unit-testable logic?
    ├─ Yes → Write Vitest/Jest test (use test-driven-development skill)
    │
    └─ No (UI/browser) → Is it static HTML?
        ├─ Yes → Read HTML file directly for selectors
        │         └─ Playwright with file:// URL, or serve it and use Preview
        │
        └─ No (dynamic app) → Server running?
            ├─ No → Start dev server, then test
            │        preview_start via .claude/launch.json (Preview path)
            │        OR python scripts/with_server.py --help (Playwright path)
            │
            └─ Yes → Reconnaissance-then-action (below)
```

## Claude Preview Workflow

Use when testing interactively in Claude Code with the built-in Preview tools.

**Setup:** `preview_start` launches a dev server by name from `.claude/launch.json` (create it if missing — it holds the command and port). Reuses the server if already running.

### Reconnaissance-Then-Action

1. **Start** — `preview_start` (get `serverId`), check `preview_logs` for build errors
2. **Snapshot** — `preview_snapshot` to get page structure, text, and element roles
3. **Screenshot** (optional) — `preview_screenshot` for layout/appearance checks
4. **Act** — `preview_click`, `preview_fill` with CSS selectors from the snapshot
5. **Verify** — `preview_inspect` for exact styles/dimensions (more accurate than screenshots for colors and fonts); `preview_console_logs` for runtime errors; `preview_network` for failed requests

**Don't** click before snapshot on dynamic apps — wait for the page to settle.

**Responsive/dark mode:** `preview_resize` with presets (mobile/tablet/desktop) or `colorScheme` emulation.

**Alternative:** If Chrome integration (claude-in-chrome tools) is connected, you can drive a real browser tab instead — useful for testing against an already-open session.

### Common Dev Server Commands

| Project | Start | Preview (production build) |
|---------|-------|------------------------------|
| Vite | `npm run dev` (default :5173) | `npm run build && npm run preview` |
| Next.js | `npm run dev` (:3000) | `npm run build && npm start` |

**Offline projects:** Test against `localhost` only. No external CDN or API calls in test paths.

**dist sync projects:** If the repo syncs to `dist/`, test the same target the user ships (dev source vs `dist/` preview) — ask or check the project rules (CLAUDE.md or `.project_rules/`).

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
- Relying on screenshots to verify colors/fonts/spacing → use `preview_inspect` instead
- Leaving the dev server running when done → `preview_stop`

## Best Practices

- Descriptive selectors: `text=`, `role=`, CSS, IDs
- Screenshot before and after critical actions for evidence
- Stop servers (`preview_stop`) / close browser when done
- Add `page.wait_for_selector()` or equivalent waits for async UI
