## Project Context
- project_name: Agentic Human–AI Research Pipeline
- project_description: Locally executed governance-first qualitative-research pipeline enforcing blind/lens-informed two-pass analysis, mandatory human evidence adjudication, and auditable artifact integrity for sensitive psychotherapy and health-adjacent studies.
- project_type: governance-first research pipeline scaffold
- primary_language: Python
- governed_languages: python
- runtime_stack: Python 3.10+ CLI modules under `src/`; local Ollama REST inference at `http://localhost:11434`; optional local WhisperX transcription via `src/modules/transcribe_adapter.py`; JSON-schema-governed artifacts under `artifacts/`; optional OSF/institutional deposit for Pass 1 anchor upgrade; Docker template based on `python:3.12-slim`.
- current_dev_phase: phase 3 of 6 — scaffold implementation with mocked governance verification; integrations and hardening phases remain partial/not started
- repo_boundaries:
  - product_surface: `src/`, `tests/`, `artifacts/`, `examples/`, `config/`, `docs/`, `docker/`, `README.md`, `requirements.txt`, `notebooks/` (empty/planned), `osf_deposit_example/` (empty/planned), `html-archive/` (archived source documents)
  - implementation_governance: `implementation docs/`, `GUARDRAILS.md`, `COPILOT_INSTRUCTIONS.md`, `CONTRIBUTING.md`, `HOW_TO_COMPLY.md`, `LICENSE`, `COMMERCIAL_LICENSE.md`, `.github/workflows/ci.yml`, `Makefile`, `docs/error_codes.md`, `config/secrets.example.yaml`, `scripts/check.sh`, `scripts/preflight.sh`, `scripts/lint-check.sh`, `scripts/verify-integrity.sh`, `scripts/lint-adapters/`
  - framework_tooling: `.opencode/`, `.ai-layer/`, `opencode.json`, `.github/AGENT-SYSTEM.md`, `.github/agents/`, `package.json`, `templates/`, `scripts/project-init.sh`, `scripts/state.sh`, `scripts/retry-budget.sh`, `scripts/session-start.sh`, `scripts/set-autonomy.sh`, `scripts/sync-mag-agent-name.sh`, `scripts/bootstrap.sh`, `scripts/probe-stack.sh`, `scripts/snapshot.sh`, `scripts/phase-complete.sh`
- custom_models:
  - planner: unset — update manually
  - executor: unset — update manually
  - reviewer: unset — update manually

## Operational Constraints
- max_file_lines: 300
- max_function_lines: 50
- verification_commands:
  - lint: `make lint`
  - test: `make test-local` (`make test` is equivalent CI target)
  - build: N/A
- required_verification_env:
  - `MOCK_LLM=true`
  - `REVIEWER_ID` (only when driving `review_cli.py` non-interactively)
  - `OSF_TOKEN` (optional runtime only; not needed for tests)

## Runtime Model Behaviour
- compensating_constraints:
  - Participant data processing is local-only; Ollama is the only LLM path and transcription must stay local.
  - Pass 2 hard-blocks unless Pass 1 anchor exists, Pass 1 hash matches file content, anchor is externally upgraded, lens is locked and signed, and DPIA exists for `special_category`.
  - `human_verdict` must remain null until set by a human through `src/tools/review_cli.py`.
  - Governed artifacts require `strand` labels, SHA256 tracking, and append-only behavior after lock points.
  - Errors must use structured codes from `docs/error_codes.md`; CI/tests run mocked without live model/network.
  - Full structural constraints (prohibited integrations, atomic writes, prompt location/hash, filesystem safety, reviewer identity, model_config metadata) are canonical in `ARCHITECTURE.md`.

## Data Sensitivity
- data_sensitivity: sensitive
- sensitivity_reason: The system targets psychotherapy and health-adjacent qualitative workflows and explicitly enforces GDPR Article 9 DPIA gating for special-category processing.
- legal_framework: UK GDPR Article 9 + BPS Code of Ethics and Conduct (2021)
- data_egress_policy: approved external only
