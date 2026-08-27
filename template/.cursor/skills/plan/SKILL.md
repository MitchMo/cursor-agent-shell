---
name: plan
description: Orchestrates the full AI dev team pipeline (Planner → Designer/Backend/Frontend → Tester → Reviewer) for a feature request. Use when the user invokes /plan.
disable-model-invocation: true
---

# Plan — Full Pipeline Orchestrator

Run the multi-agent development pipeline for the feature request provided after `/plan`.

## Parse

Extract the feature request from all text after the `/plan` invocation. If no feature request is provided, ask the user what they want to build.

## Phase 1: Plan

Launch the `planner` subagent (foreground) with this prompt:

```
Feature request: <feature request>

Explore the repository layout first. Use the project's real module/folder structure.
Write the overview and Work Assignment to agent-outputs/pipeline/spec.md.
Also write the applicable specialist artifacts:
- agent-outputs/pipeline/api_contracts.json (when an API boundary exists)
- agent-outputs/pipeline/specs/design_spec.md (if designer is assigned)
- agent-outputs/pipeline/specs/backend_spec.md (if backend is assigned)
- agent-outputs/pipeline/specs/frontend_spec.md (if frontend is assigned)

Partition file ownership so specialists do not overlap.
Encode parallel groups: designer + backend together when both assigned; frontend after design tokens exist.
Do not invent top-level src/ or tests/ directories if the project already uses another layout.
Do not write implementation code.
```

After the planner completes:
- Read `agent-outputs/pipeline/spec.md` to verify it was written with substantive content.
- Confirm specialist specs/contracts referenced in Work Assignment exist.
- If the overview is missing or empty, retry the planner once with the same prompt.
- If still missing, stop and report the failure.

## Phase 2: Present and Approve

Summarize the plan for the user:
- Feature overview
- Modules / areas of the repo in scope
- Assigned specialists and parallel groups
- Key contracts (API / design)
- Files each specialist will own
- Acceptance criteria

**Pause and wait for user approval** before continuing. Accept "continue", "proceed", "yes", "go ahead", or similar confirmation. Do not proceed to implementation without approval.

## Phase 3: Implement (specialists)

Read Work Assignment from `agent-outputs/pipeline/spec.md` to determine which of `designer`, `backend`, and `frontend` are assigned.

### Phase 3a — Parallel group 1

In a **single turn**, launch every assigned agent from `{designer, backend}` **in parallel** (multiple Task tool calls together). Skip any not assigned.

**Designer prompt** (if assigned):

```
Read agent-outputs/pipeline/spec.md and agent-outputs/pipeline/specs/design_spec.md.
Write concrete design tokens and layout rules to agent-outputs/pipeline/design_tokens.json.
Do not write application source code.
Summarize token groups when done.
```

**Backend prompt** (if assigned):

```
Read agent-outputs/pipeline/spec.md, agent-outputs/pipeline/specs/backend_spec.md, and agent-outputs/pipeline/api_contracts.json.
Implement the backend exactly as specified on the owned real project paths.
Match the API contract for routes, payloads, and errors.
Do not edit frontend files.
Summarize files changed when done.
```

Wait for all Phase 3a agents to finish before continuing.

If designer was assigned, verify `agent-outputs/pipeline/design_tokens.json` exists with substantive content. If missing, retry designer once.

### Phase 3b — Frontend (after dependencies)

If `frontend` is assigned, launch the `frontend` subagent (foreground) with:

```
Read agent-outputs/pipeline/spec.md, agent-outputs/pipeline/specs/frontend_spec.md,
agent-outputs/pipeline/design_tokens.json (if present), and agent-outputs/pipeline/api_contracts.json.
Implement the UI exactly as specified on the owned real project paths.
Adhere to design tokens and API contracts.
Do not edit backend files.
Summarize files changed when done.
```

If designer was not assigned but frontend is, proceed using whatever design guidance exists in the frontend spec (and existing project styles).

## Phase 4: Test

Launch the `tester` subagent (foreground) with this prompt:

```
Read agent-outputs/pipeline/spec.md and all specialist specs under agent-outputs/pipeline/specs/.
Review implementation files owned by backend and/or frontend.
Write comprehensive unit and integration tests covering happy paths and edge cases from the specs.
Place tests in the project's existing test locations (as listed in the overview spec).
Do not invent a top-level tests/ directory if the project uses another convention.
Include cross-boundary tests when both backend and frontend were in scope.
```

## Phase 5: Review

Launch the `reviewer` subagent (foreground) with this prompt:

```
Read agent-outputs/pipeline/spec.md, specialist specs, api_contracts.json, and design_tokens.json (if present).
Then read the implementation and test files listed in those specs.
Write your evaluation to agent-outputs/pipeline/review.md ending with a strict PASS or FAIL verdict.
If FAIL, list specific remediation steps with file paths and name the responsible specialist (designer | backend | frontend).
```

After the reviewer completes, read `agent-outputs/pipeline/review.md` and check the final verdict.

## Phase 6: Handle Verdict

If the verdict is **FAIL**:
1. Summarize the reviewer's findings and remediation steps for the user.
2. Ask whether to retry (specialists → tester → reviewer loop).
3. If the user approves, re-run only the specialists named in remediation (or all previously assigned if unclear), then tester and reviewer. Include remediation context in each specialist prompt.
4. Respect dependencies: if frontend must be retried after designer/backend fixes, re-run frontend after those complete.
5. Maximum 2 retry iterations. After that, stop and report remaining issues.

If the verdict is **PASS**, proceed to the final report.

## Final Report

Print a structured execution summary:

```
Pipeline Complete
─────────────────
Feature: <feature request>
Phases: Plan → Implement (specialists) → Test → Review
Specialists: <designer | backend | frontend that ran>
Spec: agent-outputs/pipeline/spec.md
Contracts: agent-outputs/pipeline/api_contracts.json (if used)
Design tokens: agent-outputs/pipeline/design_tokens.json (if used)
Review: agent-outputs/pipeline/review.md
Verdict: PASS | FAIL
Files touched: <list of real project paths>
Retries: <count>
```

If FAIL after all retries, list outstanding remediation steps from `agent-outputs/pipeline/review.md`.
