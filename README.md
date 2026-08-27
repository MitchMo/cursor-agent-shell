# AI Dev Team Shell for Cursor

An importable multi-agent development team that runs inside Cursor. Planner, Designer, Backend, Frontend, Tester, and Reviewer agents collaborate through a contract-driven file bus under `agent-outputs/pipeline/`.

Works in single-package apps **and** monorepos: agents live at the repo root, and specialists write into the project's real module paths (not a fake top-level `src/` / `tests/`).

## Quick Start

```bash
# Install into an existing project (or monorepo root)
./install.sh /path/to/your-project

# Or install into the current directory
./install.sh .
```

Then open the project in Cursor and run:

```
/plan Add user login portal
```

For a step-by-step walkthrough of what happens at each phase (with example file outputs), see [EXAMPLE_WALKTHROUGH.md](EXAMPLE_WALKTHROUGH.md).

## How It Works

The main agent orchestrates specialists through a hub-and-spoke pipeline:

1. **Planner** — explores the repo, writes an overview + Work Assignment to `agent-outputs/pipeline/spec.md`, plus split specs and `api_contracts.json`
2. **Designer + Backend** — run **in parallel** when both are assigned (tokens vs API implementation)
3. **Frontend** — runs after design tokens (and contracts) are ready
4. **Tester** — writes tests in the project's existing test locations
5. **Reviewer** — audits everything and writes **PASS** or **FAIL** to `agent-outputs/pipeline/review.md`

Agents pass context through files on disk (the "file bus"), not conversation history. Shared contracts keep parallel specialists synchronized.

```
/plan feature request
  → planner   → spec.md + specialist specs + api_contracts.json
  → [user approval]
  → designer  ┐ parallel → design_tokens.json
  → backend   ┘          → real backend paths
  → frontend  → real frontend paths (after tokens/contracts)
  → tester    → real test locations
  → reviewer  → review.md (PASS | FAIL)
  → [retry loop on FAIL — targeted specialists]
```

Planner only assigns the specialists a feature needs (backend-only work skips designer/frontend).

## Skills

| Skill | Purpose |
|-------|---------|
| `/plan` | Full pipeline: plan → specialists → test → review |
| `/implement` | Specialist phase only (requires Work Assignment in `spec.md`) |
| `/test` | Tester phase only (requires implementation from the specs) |
| `/review` | Reviewer phase only (requires specs + implementation + tests) |

Use individual skills when you want manual control over each phase.

## Directory Layout

After installation, your project will have:

```text
your-project/                    # or monorepo root
├── .cursor/
│   ├── agents/                  # planner, designer, backend, frontend, tester, reviewer
│   └── skills/                  # plan, implement, test, review
├── agent-outputs/
│   └── pipeline/
│       ├── prompts/             # Reference prompts
│       ├── spec.md              # Overview + Work Assignment (Planner)
│       ├── api_contracts.json   # Shared API contract (Planner)
│       ├── design_tokens.json   # Design tokens (Designer)
│       ├── specs/               # design_spec, backend_spec, frontend_spec
│       └── review.md            # PASS/FAIL (Reviewer)
├── endpoints/ …                 # your real modules (unchanged by install)
├── services/ …
└── web/ …
```

The installer does **not** create `src/` or `tests/` at the root. Application code and tests stay in whatever layout your project already uses.

## Monorepo Notes

Install once at the **repository root** so Cursor can discover agents for the whole workspace.

The Planner is responsible for choosing modules, partitioning ownership, and concrete paths. Example for a multi-module Java + web repo:

- Scope: `endpoints`, `services`, `web/app`
- Backend: `endpoints/src/main/java/...`
- Frontend: `web/app/src/...`
- Designer: `agent-outputs/pipeline/design_tokens.json`
- Tests: module-local paths per project convention

## File Bus Contract

| File | Written by | Read by |
|------|-----------|---------|
| `agent-outputs/pipeline/spec.md` | Planner | All specialists, Tester, Reviewer |
| `agent-outputs/pipeline/api_contracts.json` | Planner | Backend, Frontend, Reviewer |
| `agent-outputs/pipeline/specs/*_spec.md` | Planner | Matching specialist, Tester, Reviewer |
| `agent-outputs/pipeline/design_tokens.json` | Designer | Frontend, Reviewer |
| Real source paths from the specs | Backend / Frontend | Tester, Reviewer |
| Real test paths from the overview | Tester | Reviewer |
| `agent-outputs/pipeline/review.md` | Reviewer | Orchestrator (for FAIL retry) |

## FAIL / Retry Behavior

When `/plan` runs the full pipeline and the Reviewer returns **FAIL**:

1. The orchestrator summarizes findings (with specialist owners) and asks whether to retry.
2. On approval, it re-runs the named specialists (respecting designer/backend → frontend dependencies), then Tester → Reviewer.
3. Maximum 2 retry iterations before stopping and reporting remaining issues.

For manual iteration, read `agent-outputs/pipeline/review.md` and run `/implement` with the feedback, then `/test` and `/review`.

## Customization

### Agents

Edit files in `.cursor/agents/` to change agent behavior:

- `planner.md` — planning style, contract format, work assignment rules
- `designer.md` — token structure and design conventions
- `backend.md` — API/coding conventions
- `frontend.md` — UI conventions
- `tester.md` — test framework preferences
- `reviewer.md` — review criteria, strictness

Each agent supports frontmatter fields: `name`, `description`, `model`, `readonly`.

To pin a specific model, set `model` in frontmatter:

```yaml
model: claude-opus-5[effort=high]
```

### Skills

Edit files in `.cursor/skills/` to change workflow behavior (approval gates, retry limits, parallel dispatch).

## Re-installing / Migrating

Running `install.sh` again is safe. Existing files are skipped (not overwritten). To get updated agent definitions, delete the specific files in `.cursor/agents/` or `.cursor/skills/` and re-run the installer.

If you previously installed the single-`coder` layout:

1. Delete `.cursor/agents/coder.md` (and old skills if you want a full refresh).
2. Re-run `./install.sh .` to pick up `designer.md`, `backend.md`, `frontend.md`, and updated skills.
3. Optionally delete obsolete `agent-outputs/pipeline/prompts/2_coder.md` if it remains from an older install.

## Architecture Reference

For the original design rationale and Claude Desktop workflow, see [ai_dev_team_setup_guide.md](ai_dev_team_setup_guide.md).
