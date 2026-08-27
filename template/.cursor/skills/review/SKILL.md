---
name: review
description: Runs the Reviewer agent to audit the specs, contracts, and project changes. Writes PASS/FAIL to agent-outputs/pipeline/review.md. Use when the user invokes /review.
disable-model-invocation: true
---

# Review — Reviewer Phase

Run the Reviewer agent to audit the current implementation and tests.

## Prerequisites

Before delegating, verify:
- `agent-outputs/pipeline/spec.md` exists and contains substantive content.
- Implementation files listed in the specialist specs exist.
- Test files listed under Test Locations exist.

If any prerequisite is missing, stop and tell the user which phase to run first.

## Execute

Launch the `reviewer` subagent (foreground) with this prompt:

```
Read agent-outputs/pipeline/spec.md, specialist specs, api_contracts.json, and design_tokens.json (if present).
Then read the implementation and test files listed in those specs.
Write your evaluation to agent-outputs/pipeline/review.md ending with a strict PASS or FAIL verdict.
If FAIL, list specific remediation steps with file paths and name the responsible specialist (designer | backend | frontend).
```

## Report

After completion, read `agent-outputs/pipeline/review.md` and summarize:
- Verdict: **PASS** or **FAIL**
- Key findings
- If FAIL: remediation steps (with specialist owners) and suggestion to run `/implement` with the review feedback
