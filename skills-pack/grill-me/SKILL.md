---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

# Grill Me

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Workflow

1. **Capture the plan** — Restate what you understand in 2–3 sentences. Ask the user to confirm or correct before grilling.
2. **Map the decision tree** — Identify top-level branches (scope, data, UX, failure modes, constraints, rollout, etc.). Work depth-first: finish one branch before opening siblings.
3. **One question per turn** — Never batch multiple questions. Wait for the answer before the next.
4. **Recommend before asking** — For each question, state your recommended answer and why, then ask the user to confirm, reject, or refine.
5. **Codebase first** — If the answer lives in the repo (existing patterns, config, APIs), explore the codebase and report findings instead of asking the user.
6. **Resolve dependencies** — When a decision blocks another, resolve the blocker first. Record settled decisions briefly as you go.
7. **Close the loop** — When all branches are resolved, produce a short shared-understanding summary: decisions made, open risks, and assumptions still unverified.

## Question format

Each turn:

```
**Branch:** [which part of the design tree]

**Context:** [why this matters now]

**My recommendation:** [answer + rationale]

**Question:** [single, specific question]
```

## Rules

- Do not implement code unless the user explicitly asks to move from design to implementation.
- Do not accept vague answers — push for concrete choices (numbers, boundaries, failure behavior).
- If the user contradicts an earlier decision, surface the conflict and reconcile before continuing.
- Prefer exploring the codebase over asking the user about facts already encoded in the project.
