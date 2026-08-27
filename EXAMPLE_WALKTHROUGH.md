# Example Walkthrough: Building a Feature with the AI Dev Team

This document walks through a concrete example to show what happens at each step when you use the AI Dev Team Shell in Cursor.

Two scenarios are covered:

1. **Full-stack feature** — designer + backend + frontend in parallel where possible
2. **Monorepo** — like `saleslogic`, with multiple modules and no root `src/` / `tests/`

---

## Before You Start

Assuming you've already installed the shell into your project (or monorepo root):

```bash
./install.sh /path/to/your-project
```

Your project should have this layout from the installer:

```text
your-project/
├── .cursor/agents/              # planner, designer, backend, frontend, tester, reviewer
├── .cursor/skills/              # plan, implement, test, review
└── agent-outputs/pipeline/
    ├── spec.md                  # overview placeholder
    ├── api_contracts.json
    ├── design_tokens.json
    ├── specs/                   # design / backend / frontend placeholders
    └── review.md
```

No root `src/` or `tests/` folders are created. Existing modules stay as they are.

---

## Option A: Full Pipeline with `/plan` (full-stack)

Example feature: **"Add a health status badge that calls GET /health"**

### Step 1 — You invoke the pipeline

In Cursor chat, type:

```
/plan Add a health status badge that calls GET /health
```

The `/plan` skill loads. The orchestrator extracts your feature request and begins Phase 1.

---

### Step 2 — Planner agent runs

**Who:** `planner` subagent (`.cursor/agents/planner.md`)

**What it does:**
1. Reads your feature request
2. Explores the existing codebase (layout, conventions, test setup)
3. Assigns specialists and partitions file ownership
4. Writes overview + contracts + split specs

**What gets written:**
- `agent-outputs/pipeline/spec.md` — overview + Work Assignment
- `agent-outputs/pipeline/api_contracts.json`
- `agent-outputs/pipeline/specs/design_spec.md`
- `agent-outputs/pipeline/specs/backend_spec.md`
- `agent-outputs/pipeline/specs/frontend_spec.md`

**Example Work Assignment** (in `spec.md`):

```markdown
## Work Assignment
- Agents: designer, backend, frontend
- Parallel group 1: designer, backend
- After group 1: frontend

## Shared Contracts
- agent-outputs/pipeline/api_contracts.json
- agent-outputs/pipeline/design_tokens.json (Designer)
```

**Example API contract** (`api_contracts.json`):

```json
{
  "endpoints": [
    {
      "method": "GET",
      "path": "/health",
      "response": {
        "status": "string",
        "checkedAt": "string"
      }
    }
  ]
}
```

**What you see in chat:** The orchestrator summarizes the plan (including which specialists run in parallel) and **waits for your approval**.

---

### Step 3 — You approve the plan

Reply with something like:

```
continue
```

---

### Step 4 — Designer + Backend run in parallel

**Who:** `designer` and `backend` subagents (launched together)

**Designer** writes `agent-outputs/pipeline/design_tokens.json` (colors, spacing, badge states, etc.).

**Backend** implements the owned API paths to match `api_contracts.json`.

---

### Step 5 — Frontend runs

**Who:** `frontend` subagent

**What it does:** Reads `frontend_spec.md`, `design_tokens.json`, and `api_contracts.json`, then builds the UI on owned paths.

---

### Step 6 — Tester agent runs

**Who:** `tester` subagent

**What it does:** Writes tests at the locations named in the overview spec, including cross-boundary coverage when both backend and frontend shipped.

---

### Step 7 — Reviewer agent runs

**Who:** `reviewer` subagent (read-only)

**What gets written:** `agent-outputs/pipeline/review.md`

Ends with a strict **PASS** or **FAIL** verdict. On FAIL, remediation steps name the responsible specialist (`designer` | `backend` | `frontend`). The orchestrator can retry those specialists (max 2), then re-test and re-review.

---

## Option B: Monorepo at the repo root (e.g. saleslogic)

Install once at the **top of the monorepo**:

```bash
./install.sh /path/to/saleslogic
```

Layout after install:

```text
saleslogic/
├── .cursor/                     # agents + skills for the whole repo
├── agent-outputs/pipeline/      # specs + contracts + reviews only
├── endpoints/
├── services/
├── web/app/
└── …
```

Example request:

```
/plan Add a GET /health endpoint in the endpoints module and show status in the web app
```

### What the Planner should produce

`spec.md` Work Assignment plus partitioned ownership, for example:

```markdown
## Modules/Scope
- endpoints (Quarkus API) — backend
- web/app (Vite frontend) — frontend
- design tokens — designer

## Files owned by backend
- endpoints/src/main/java/.../HealthResource.java

## Files owned by frontend
- web/app/src/components/HealthBadge.tsx

## Test Locations
- endpoints/src/test/java/.../HealthResourceTest.java
- web/app/src/components/HealthBadge.test.tsx
```

### What specialists do

- Designer writes tokens under `agent-outputs/pipeline/`
- Backend edits `endpoints/...` — not a fake root `src/`
- Frontend edits `web/app/...` after tokens exist
- Tester writes beside those modules using existing Maven / Vitest conventions
- Reviewer reads those same paths and writes the verdict to `review.md`

This is the intended model for multi-project repos: **agents at the top, code changes in the real modules**.

### Backend-only example

If the request is API-only, Planner assigns only `backend`. `/plan` skips designer and frontend.

---

## Option C: Manual Phase-by-Phase

| Command | Requires |
|---------|----------|
| `/plan …` | Feature request |
| `/implement` | Work Assignment in `agent-outputs/pipeline/spec.md` + specialist specs |
| `/test` | Specs + implementation files |
| `/review` | Specs + implementation + tests |

Useful when you want to inspect or edit contracts between phases.

---

## File Bus at a Glance

After a successful full-stack run:

```text
your-project/
├── agent-outputs/pipeline/
│   ├── spec.md              ← Planner (overview)
│   ├── api_contracts.json   ← Planner
│   ├── design_tokens.json   ← Designer
│   ├── specs/               ← Planner (split specs)
│   └── review.md            ← Reviewer (PASS)
├── <backend paths>          ← Backend
├── <frontend paths>         ← Frontend
└── <test paths>             ← Tester
```

Context flows through the filesystem:

- You can open any artifact and inspect it anytime
- You can edit contracts/specs between phases
- Re-running `/implement` after editing specs uses the updated contracts
- The Reviewer's verdict in `review.md` is the source of truth for PASS/FAIL

---

## Timeline Summary

| Step | Who acts | Input | Output | You do |
|------|----------|-------|--------|--------|
| 1 | You | — | `/plan <request>` | Type the command |
| 2 | Planner | Feature request + repo layout | Overview + contracts + split specs | Review the summary |
| 3 | You | — | "continue" | Approve the plan |
| 4 | Designer + Backend | Specs + contracts | Tokens + backend code | Wait (parallel) |
| 5 | Frontend | Specs + tokens + contracts | Frontend code | Wait |
| 6 | Tester | Specs + code | Real test paths | Wait |
| 7 | Reviewer | Specs + code + tests | `review.md` | Read the verdict |
| 8 | Orchestrator | Review verdict | Summary in chat | Retry if FAIL, or done |

---

## Tips

- **Install at the monorepo root** when multiple packages share one git repo.
- **Read the artifacts.** Specs, contracts, and review under `agent-outputs/pipeline/` are human checkpoints.
- **Trust the project's layout.** If Planner invents a wrong top-level `src/`, reject approval and ask it to use real module paths.
- **Partition ownership.** Specialists must not edit the same files.
- **Customize agents.** Edit `.cursor/agents/*.md` for team conventions (framework, test runner, review strictness).

For architecture background, see [ai_dev_team_setup_guide.md](ai_dev_team_setup_guide.md). For install and customization, see [README.md](README.md).
