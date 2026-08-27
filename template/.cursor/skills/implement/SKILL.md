---
name: implement
description: Runs assigned Designer/Backend/Frontend specialists to implement the current pipeline specs. Use when the user invokes /implement.
disable-model-invocation: true
---

# Implement — Specialist Phase

Run the implementation specialists for the current specification.

## Prerequisites

Before delegating, verify:
- `agent-outputs/pipeline/spec.md` exists and contains substantive content (not just the placeholder header), including a Work Assignment section.

If missing, stop and tell the user to run `/plan` first or create a spec manually.

Read Work Assignment to determine which of `designer`, `backend`, and `frontend` are assigned. Verify each assigned specialist's input files exist:
- designer → `agent-outputs/pipeline/specs/design_spec.md`
- backend → `agent-outputs/pipeline/specs/backend_spec.md` and usually `agent-outputs/pipeline/api_contracts.json`
- frontend → `agent-outputs/pipeline/specs/frontend_spec.md` (and `api_contracts.json` / `design_tokens.json` when referenced)

If a required input is missing, stop and report it.

## Execute

### Parallel group 1

In a **single turn**, launch every assigned agent from `{designer, backend}` **in parallel**.

**Designer** (if assigned):

```
Read agent-outputs/pipeline/spec.md and agent-outputs/pipeline/specs/design_spec.md.
Write concrete design tokens and layout rules to agent-outputs/pipeline/design_tokens.json.
Do not write application source code.
Summarize token groups when done.
```

**Backend** (if assigned):

```
Read agent-outputs/pipeline/spec.md, agent-outputs/pipeline/specs/backend_spec.md, and agent-outputs/pipeline/api_contracts.json.
Implement the backend exactly as specified on the owned real project paths.
Match the API contract for routes, payloads, and errors.
Do not edit frontend files.
Summarize files changed when done.
```

Wait for group 1 to finish. If designer was assigned, verify `design_tokens.json` was written.

### Frontend

If `frontend` is assigned, launch `frontend` after group 1:

```
Read agent-outputs/pipeline/spec.md, agent-outputs/pipeline/specs/frontend_spec.md,
agent-outputs/pipeline/design_tokens.json (if present), and agent-outputs/pipeline/api_contracts.json.
Implement the UI exactly as specified on the owned real project paths.
Adhere to design tokens and API contracts.
Do not edit backend files.
Summarize files changed when done.
```

## Report

After completion, summarize:
- Which specialists ran
- Files created or modified (real project paths) and design token path if written
- Any deviations from the specs (if a specialist noted any)
- Suggested next step: run `/test` then `/review`, or `/plan` for the full pipeline
