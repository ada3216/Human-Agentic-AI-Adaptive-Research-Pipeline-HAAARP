Plan: Re-run project-init steps 16-19 with Python-only lint governance
Scope: CONTAINED
Risk: MEDIUM
Date: 2026-04-21
Target surface: MIXED

Context sources used
- `.opencode/commands/project-init.md` (steps 16-19 requirements)
- `.ai-layer/PROJECT_CONFIG.md` (authoritative governed_languages=Python, sensitivity=sensitive)
- `.ai-layer/ARCHITECTURE.md` (authoritative governance constraints)
- `.ai-layer/lint-rules/tier-1/*` (current rule inventory)
- `docker/Dockerfile` (FROM baseline check)
- `opencode.json` (permission block check)
- `.ai-layer/decisions.md` (append-only INIT logging)

Architectural constraints this plan operates within
- Governed languages are Python-only; lint artifacts must not include non-governed language rules.
- Sensitive-project permissions must remain `"permission": { "edit": "ask", "bash": "ask" }`.
- Docker base image for Python-primary remains `python:3.12-slim`.
- decisions.md is append-only and must record an INIT entry for this rerun.
- Step 16 requires MCP memory writes via `mcp_memory_create_entities` for each confirmed lint rule (`entityType: constraint`).

Design decisions resolved
- User-approved design-stop already grants refinement authority to re-run only steps 16-19 against current ARCHITECTURE/PROJECT_CONFIG.

Why this approach
This narrows execution to the approved post-draft initialization tail, aligns lint governance with authoritative Python-only scope, and avoids re-running broader project-init discovery/drafting work that is out of scope.

What is being removed
- Non-governed tier-1 lint rule files and docs for JavaScript, TypeScript, and Shell under `.ai-layer/lint-rules/tier-1/`.
- Any extra Python tier-1 rule artifacts beyond exactly two rules and their two matching `.rules.md` files.

Implementation steps
1. Reconcile `.ai-layer/lint-rules/tier-1/` to Python-only: keep/create exactly two Python rules (`python-module-size.ruff.toml`, `python-pattern-no-print.ruff.toml`) and matching docs (`python-module-size.rules.md`, `python-pattern-no-print.rules.md`); delete JS/TS/Shell tier-1 rule files.
2. Execute step-16 memory expectations: create two MCP memory constraint entities (one per confirmed Python rule) using `mcp_memory_create_entities` with rule description and project name observations.
3. Verify `docker/Dockerfile` FROM is exactly `python:3.12-slim`; update only if drifted.
4. Verify `opencode.json` permission block is `edit=ask` and `bash=ask`; update only if drifted.
5. Append one INIT record to `.ai-layer/decisions.md` dated today with project name, Python language list, sensitive classification, and `rules confirmed: 2`.

Acceptance criteria
- `.ai-layer/lint-rules/tier-1/` contains exactly 4 relevant Python tier-1 artifacts: 2 rule files (`*.ruff.toml`) + 2 matching `.rules.md`, with no JS/TS/Shell tier-1 rule files remaining.
- MCP memory creation is performed for exactly 2 constraint entities, one per confirmed Python rule (step 16 compliance).
- `docker/Dockerfile` contains `FROM python:3.12-slim`.
- `opencode.json` contains `"permission": { "edit": "ask", "bash": "ask" }`.
- `.ai-layer/decisions.md` has a new append-only INIT entry for 2026-04-21 ending with `rules confirmed: 2`.
- Key governance constraint still holds: configured governed language scope is Python-only per `.ai-layer/PROJECT_CONFIG.md`.

─────────────────────────────────────────
NEXT STEP
Command:  /implement
Action:   Review the plan above. Run /implement to proceed.
─────────────────────────────────────────
