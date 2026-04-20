# Architecture

## What this system does

This system enforces a governance-first human–AI delivery loop for planning, implementation, and independent review. It coordinates state transitions, stop semantics, lint/test gates, retry budgeting, and decision logging so changes are auditable and operationally controlled across domains.

## Who uses it and how

- Human operators define goals, answer DESIGN_STOP decisions, and approve governance posture.
- Planner agents create ordered implementation plans and raise explicit design decisions when ambiguity affects architecture.
- Executor agents implement approved plans, run checks, and produce commit-ready artifacts with traceable state updates.
- Reviewer agents run on a different provider where possible, verify drift against architecture constraints, and record PASS/FAIL outcomes.

## Non-negotiable architectural patterns

- State-gated workflow only: phase transitions must go through `scripts/state.sh`; no direct state file mutation.
- Role separation by command: planning, implementation, and review responsibilities stay distinct and observable.
- Stop semantics are authoritative: DESIGN_STOP blocks implementation decisions; REVIEW_STOP blocks new planning/implementation until resolved.
- Audit-first operations: each phase and escalation must append durable decision records and maintain session-level tool logs.
- Deterministic command-driven transitions: required checks (`lint`, `check.sh`, retry budget, commit gate) run in explicit order before completion.

## Non-negotiable constraints

- Secrets or credentials must not be committed to repository history or logs.
- Gate checks and review controls cannot be bypassed without explicit documented override.
- Operational bounds are mandatory: max file lines and max function lines from `PROJECT_CONFIG.md` must be respected.
- Autonomous architectural decisions are disallowed when unresolved design choices materially change implementation.
- Data egress paths must be explicit, documented, and policy-aligned; undocumented outbound flows are prohibited.

## Why this system exists (north star)

The system exists to make AI-assisted delivery reliable under governance pressure: fast iteration with explicit control points, independent verification, and reproducible evidence of why each change was made. Success is measured by consistent policy adherence, low decision ambiguity, and reviewable artifacts that remain trustworthy across teams and project types.

## Data flow (sensitive data)

- Configuration and state: read/write locally via controlled scripts; state changes are command-mediated and auditable.
- Decision and audit logs: appended as local repository artifacts intended for governance traceability; must exclude secret values.
- Working code and generated artifacts: processed in workspace scope, checked by local gates, and committed only after policy checks pass.
- Optional memory entities: limited to approved workflow events (for example, last-task metadata) with no credential content.
- Prohibited paths: raw secrets in commits/logs, silent third-party uploads, and undocumented external transmission of sensitive data.

## Project Ethos

Ship quickly, but only through visible controls. Prefer explicit decisions over implicit behavior, local handling over unnecessary egress, and verifiable process evidence over assumptions.
