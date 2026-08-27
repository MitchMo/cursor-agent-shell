---
name: test
description: Runs the Tester agent to write tests for recent implementation changes. Use when the user invokes /test.
disable-model-invocation: true
---

# Test — Tester Phase

Run the Tester agent to write tests for the current implementation.

## Prerequisites

Before delegating, verify:
- `agent-outputs/pipeline/spec.md` exists and contains substantive content.
- Implementation files owned by assigned specialists exist (check Work Assignment and specialist specs under `agent-outputs/pipeline/specs/`).

If either is missing, stop and tell the user which prerequisite failed and what to run first (`/plan` or `/implement`).

## Execute

Launch the `tester` subagent (foreground) with this prompt:

```
Read agent-outputs/pipeline/spec.md and all specialist specs under agent-outputs/pipeline/specs/.
Review implementation files owned by backend and/or frontend.
Write comprehensive unit and integration tests covering happy paths and edge cases from the specs.
Place tests in the project's existing test locations (as listed in the overview spec).
Do not invent a top-level tests/ directory if the project uses another convention.
Include cross-boundary tests when both backend and frontend were in scope.
```

## Report

After completion, summarize:
- Test files created (real project paths)
- Coverage areas (happy paths, edge cases, cross-boundary if any)
- Suggested next step: run `/review`
