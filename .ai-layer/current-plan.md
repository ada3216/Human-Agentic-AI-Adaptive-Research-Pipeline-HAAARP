# Plan: Complete project initialization from confirmed decisions

Scope: STRUCTURAL
Risk: MEDIUM
Date: 2026-04-20

## Design decisions resolved
- Accept inferred defaults.
- Project type set to `production`.
- Data sensitivity set to `sensitive` (therapy/health/special-category + DPIA workflow reason retained).
- Custom models remain unset for planner/executor/reviewer.
- Remove runtime verbosity from PROJECT_CONFIG entirely.
- Accept inferred project ethos.
- Proceed directly to implementation after planning.

## Why this approach
Write the initialization artifacts in one coordinated pass so configuration, architecture, lint governance, container baseline, permissions, and audit log stay internally consistent for a sensitive production repository. An incremental alternative (updating files piecemeal over multiple phases) was not chosen because it increases drift risk between PROJECT_CONFIG, ARCHITECTURE, rule files, and permissions during setup.

## What is being removed
- Any `runtime_verbosity` (or equivalent runtime verbosity field) from `.ai-layer/PROJECT_CONFIG.md`.
- Any prior placeholder/unset initialization content replaced by confirmed inferred values.

## Implementation steps
1. Create or overwrite `.ai-layer/PROJECT_CONFIG.md` with required project-init headers and confirmed values: project name/description, governed languages, stage, project type `production`, data sensitivity `sensitive`, and custom models unset; omit runtime verbosity field entirely.
2. Create or overwrite `.ai-layer/ARCHITECTURE.md` with the inferred and confirmed architecture content (summary, patterns, constraints, north star, sensitive data flow, and accepted ethos) aligned to the project-init survey findings.
3. Create `.ai-layer/lint-rules/tier-1/` artifacts for each detected language with two rules each (8 total rule files) and create a matching `.rules.md` rationale file for every rule.
4. Inspect `docker/Dockerfile` and update `FROM` to `python:3.12-slim` if the base image differs and mixed-language baseline alignment is required.
5. Update `opencode.json` by writing the sensitive-project permission block required for this repository profile.
6. Append an `INIT` entry to `.ai-layer/decisions.md` with today’s date and the confirmed initialization values, explicitly noting runtime verbosity removal and accepted inferred defaults.
7. Validate resulting artifacts and state handoff expectations for review readiness (implementation will set `pending_review=true` at completion).

## Acceptance criteria
- `test -f .ai-layer/PROJECT_CONFIG.md` passes and the file includes required project-init section headers.
- `grep -n "runtime_verbosity\|verbosity" .ai-layer/PROJECT_CONFIG.md` returns no runtime verbosity field entries.
- `test -f .ai-layer/ARCHITECTURE.md` passes and contains inferred/confirmed summary, patterns, constraints, north star, sensitive data flow, and ethos.
- `test -d .ai-layer/lint-rules/tier-1` passes and exactly 16 new tier-1 files exist (8 rule files + 8 matching `.rules.md` rationale files).
- `grep -n "^FROM " docker/Dockerfile` shows `FROM python:3.12-slim` when update was needed.
- `grep -n "sensitive" opencode.json` confirms sensitive-project permission block was written.
- `.ai-layer/decisions.md` contains a new `DATE: 2026-04-20 | INIT | ...` line with confirmed values.
- Post-implementation workflow expectation is explicit: review handoff requires `pending_review=true`.

## Notes
- `ARCHITECTURE.md` is currently absent; this initialization writes the canonical file from confirmed survey inference.
- No further DESIGN_STOP is required because all listed decisions were explicitly confirmed.
