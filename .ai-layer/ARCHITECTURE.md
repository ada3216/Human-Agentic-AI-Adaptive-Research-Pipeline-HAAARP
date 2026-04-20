# Canonical architecture baseline for governance-first execution and review.

## What this system does
- project_summary: Governance-first local human–AI research pipeline that runs command-driven planning, implementation, and review with hard gates for methodological and ethics controls.

## Who uses it and how
- users_and_context: Researchers and operators use structured commands to progress work through plan, implement, and review phases with explicit approvals and audit logging.

## Non-negotiable architectural patterns
- patterns:
  - State-gated workflow transitions are command-driven and persisted through `scripts/state.sh`.
  - Planning, implementation, and review are role-separated and must not be collapsed into one unchecked step.
  - DESIGN_STOP and REVIEW_STOP semantics are mandatory when triggered by workflow state.
  - Decisions and phase completions are append-only and auditable in `.ai-layer/decisions.md`.
  - Validation runs through deterministic local scripts (`lint-check.sh`, `check.sh`) before handoff.

## Non-negotiable constraints
- constraints:
  - No secrets or credentials are committed.
  - Gates are not bypassed without explicit approved workflow exceptions.
  - File and function size limits follow project constraints (`max_file_lines: 300`, `max_function_lines: 50`).
  - No silent autonomous design changes; confirmed decisions govern initialization outputs.
  - No undocumented external data egress paths are introduced.

## Why this system exists (north star)
- north_star: Enable repeatable, transparent, and ethically governed AI-assisted qualitative research execution that remains locally auditable and reviewable at every phase.

## Data flow (sensitive data)
- data_flow:
  - Configuration and workflow state are stored locally in governed project files.
  - Decision and execution logs are append-only audit artifacts for traceability.
  - Working code and generated artifacts remain repository-local unless explicitly approved.
  - Optional memory entities store minimal task metadata and must avoid sensitive payloads.
  - Prohibited flow: unapproved export of therapy/health/special-category data or hidden network egress.

## Project Ethos
- project_ethos: Prefer explicit governance, deterministic checks, and auditable local-first execution over speed through implicit automation.
