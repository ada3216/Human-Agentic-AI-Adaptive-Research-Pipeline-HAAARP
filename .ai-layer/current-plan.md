# Plan: Rewrite ARCHITECTURE.md as generalized governance-first system

Scope: CONTAINED
Risk: MEDIUM
Date: 2026-04-20

## Why this approach
Replace `.ai-layer/ARCHITECTURE.md` with a clean forward-facing baseline anchored to what the repository now enforces at workflow level: role-based agents, DESIGN/REVIEW stops, auditability, sensitivity-aware handling, and local-first defaults. Alternative approaches (light edits to existing placeholders or copying research-domain docs) were rejected because they either preserve stale framing or reintroduce bespoke assumptions, both of which would degrade future planning and review drift checks.

## What is being removed
- Placeholder `unset` values in all architecture sections.
- Domain-specific or origin-story framing inherited from research-only documents.
- Any references implying single-domain lock-in rather than cross-domain governance workflow use.

## Implementation steps
1. Replace `.ai-layer/ARCHITECTURE.md` content entirely, preserving the required section headers: `## What this system does`, `## Who uses it and how`, `## Non-negotiable architectural patterns`, `## Non-negotiable constraints`, `## Why this system exists (north star)`, `## Data flow (sensitive data)`.
2. Add concise generalized prose in each section that describes this repository as a governance-first human–AI workflow system with configurable sensitivity, role-based agent workflow, auditable gates, and local-first defaults.
3. Define `patterns` as explicit bullet rules the planner must implement against and the reviewer must check for drift (state-gated workflow, role separation, stop semantics, audit-first decision logging, deterministic command-driven transitions).
4. Define `constraints` as hard rules that always apply (no secrets in repo, no unapproved bypass of gates, bounded file/function size from PROJECT_CONFIG, no silent autonomous design decisions, and no undocumented data egress paths).
5. Fill `Data flow (sensitive data)` with category-based flows (configuration/state, decision/audit logs, working code/artifacts, optional memory entities, and prohibited data paths) and local-first handling expectations.
6. Optionally include `## Project Ethos` only if it improves clarity without adding history/context baggage.
7. Validate final doc quality against acceptance criteria before saving.

## Acceptance criteria
- `.ai-layer/ARCHITECTURE.md` contains all required section headers exactly once.
- No `unset` tokens remain in `.ai-layer/ARCHITECTURE.md`.
- No bespoke/origin-story references remain (including named historical study context).
- `patterns` section contains actionable architecture rules reviewers can verify for drift.
- `constraints` section contains non-negotiable hard rules applicable across domains.
- Data-flow section explicitly describes sensitive data categories, allowed movement, and disallowed egress.
- Content is forward-facing, domain-agnostic, and aligned with current workflow docs (`.opencode/skills/workflow/SKILL.md`, state model, and gate semantics).

## Notes
- This is a documentation-architecture change; it does not modify runtime scripts directly, but it changes planning and review expectations for all future tasks.
