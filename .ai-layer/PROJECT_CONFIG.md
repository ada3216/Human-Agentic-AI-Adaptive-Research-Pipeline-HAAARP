## Project Context

project_name: Agentic Human–AI Research Pipeline
project_description: Governance-first pipeline for AI-assisted qualitative psychotherapy research with local-only execution, two-pass locked analysis, and auditable artifact chains.
project_type: scaffold
governed_languages: python
data_sensitivity: sensitive
rotation_policy: recommended
single_provider_mode: false
review_attestation: required
custom_models:
  planner: unset
  executor: unset
  reviewer: unset

## Operational Constraints

max_file_lines: 300
max_function_lines: 50
max_file_lines_overrides:
  .opencode/commands/project-init.md: 500
  src/modules/lens_dialogue.py: 350
  tests/test_pipeline.py: 360
max_file_lines_exempt_globs:
  - .opencode/commands/**
  - .opencode/agents/**
  - .opencode/skills/**
  - .github/agents/**
  - .github/AGENT-SYSTEM.md
  - implementation docs/**
  - docs/generic-toolkit.md
  - docs/repo-alignment-review-*
  - GUARDRAILS.md
  - package-lock.json
  - .ai-layer/current-plan.md
  - "src/modules/lens_dialogue.py": 350
  - "tests/test_pipeline.py": 360
max_function_lines_exemption_policy: "Cohesive atomic units may exceed max_function_lines when splitting would reduce auditability (for example: a single class body, a long switch/case dispatcher, or a generated config block). Keep exceptions narrow and include a local justification comment near the oversized unit."

## Runtime Model Behaviour

verbosity: unset
compensating_constraints: GUARDRAILS.md §1 (5 hard limits), §7b (artifact immutability), §7c (prompt versioning), §7d (reproducibility metadata), §7e (filesystem safety), §7f (OSF anchor validation); COPILOT_INSTRUCTIONS.md (3 absolute rules); .github/workflows/ci.yml (MOCK_LLM=true, no secrets)

## Runtime Stack

runtime: Python 3.10+
model_backend: Ollama REST API at http://localhost:11434 (local-only)
default_model: qwen2.5-27b-instruct
test_framework: pytest
linter: ruff
lint_command: make lint
test_command: make test-local
build_command: none (interpreted)
test_env: MOCK_LLM=true
ci: .github/workflows/ci.yml

## Product Source Layout

product_dirs: src/, tests/, config/, artifacts/, examples/, docs/, notebooks/, osf_deposit_example/
schemas: src/schemas/, artifacts/audit_schema.json
prompts: src/prompts/
fixtures: tests/fixtures/
config: config/defaults.yaml
secrets: config/secrets.yaml (gitignored), env vars

## Development Phase

current_dev_phase: Phase 3 complete — core modules and governance tests implemented. Phase 4 (Release package & publication) is next.
devplan: implementation docs/Agentic_Pipeline_Dev_Plan_v2.1.md

## Data Sensitivity

legal_framework: GDPR Article 9, BPS Ethics Guidelines 2021
data_egress_policy: All AI processing local-only via Ollama; no participant data to external APIs; limited export to OSF/institutional repos for governance anchors and audit bundles only after gating
