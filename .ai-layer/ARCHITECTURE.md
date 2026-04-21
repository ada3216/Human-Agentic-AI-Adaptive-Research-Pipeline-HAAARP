## ARCHITECTURE.md

## What this system does
- project_summary: Runs a local, governance-first qualitative research pipeline: ingest and de-identify source material, perform a blind Pass 1 and anchor it cryptographically, capture and lock the researcher lens, run a lens-informed Pass 2 with stability testing, grounding-check claims, require human verdicts for every claim, and emit an auditable bundle.
## Who uses it and how
- users_and_context: Researchers run local Python CLI stages on sensitive qualitative datasets. Supervisors and examiners consume the generated audit artifacts. Contributors extend the scaffold under constraints defined by `GUARDRAILS.md`, `COPILOT_INSTRUCTIONS.md`, and the dev/test plans in `implementation docs/`.
## Key Components
- `config/defaults.yaml`: Runtime config for model settings, sensitivity level, strand, stability seeds, and OSF requirements.
- `src/agent/orchestrator.py`: Main sequencer for preflight checks, sensitivity routing, ingest/de-id, Pass 1, and lens setup.
- `src/modules/dpia_gate.py`: Hard block for `special_category` runs when signed DPIA evidence is missing or invalid.
- `src/modules/ingest_and_deid.py`: Archives raw input, creates de-identified analysis files, and requires human spot-check acknowledgement.
- `src/modules/transcribe_adapter.py` (partial): Local-only transcription adapter for audio workflows; cloud transcription is prohibited.
- `src/modules/ollama_client.py`: Sole LLM client; calls local Ollama REST; provides the `MOCK_LLM=true` mock path used by all tests.
- `src/agent/pass1_runner.py`: Blind first-pass analysis; writes `pass1_output_*.json` and `pass1_anchor_*.json`.
- `src/modules/osf_uploader.py` (partial): Upgrades Pass 1 anchors from `local` to `osf_doi` or `repo_accession`; auto-upload not fully implemented.
- `src/modules/lens_dialogue.py` (partial): Captures structured researcher reflexivity, writes `lens_*.json`, locks with researcher identity.
- `src/agent/pass2_runner.py`: Enforces six preconditions, injects locked lens summary, writes seeded and deterministic outputs plus stability report.
- `src/modules/grounding_checker.py`: Creates claim-evidence review records with `human_verdict: null`; does not modify claim text.
- `src/tools/review_cli.py`: Only authorized path for human verdict entry, reviewer identity capture, and interpretive-proposition labeling.
- `src/modules/audit_emitter.py`: Validates all completion gates and emits `audit_bundle_*.zip` plus metadata.
- `src/schemas/*.json` + `artifacts/audit_schema.json`: JSON contracts for anchors, DPIA records, lens records, evidence review, stability, and audit metadata.
## Non-negotiable architectural patterns
- patterns:
  - Stage-sequenced local CLI pipeline with blocking gate checks and deterministic exit-code semantics from `docs/error_codes.md`.
  - Two-pass analysis: Pass 1 stays blind; researcher lens capture and external anchor upgrade are mandatory between Pass 1 and Pass 2.
  - Human adjudication required: grounding creates review records, `review_cli.py` resolves them, audit packaging blocks until every claim has a human verdict.
  - Local-first execution: Ollama is the sole model path; transcription must be local; `MOCK_LLM=true` is the standard verification path.
  - Artifact-centric reproducibility: structured JSON outputs, schema validation, SHA256 on write, prompt hashing, and `model_config` metadata in every LLM artifact.
  - Prompt-from-disk: operational prompts live in `src/prompts/*.txt` and are loaded at runtime, never embedded in source.
  - Atomic writes: all artifact writes use temp-then-rename to prevent partial files from being hashed or read downstream.
## Non-negotiable constraints
- constraints:
  - No participant data may be sent through external model APIs, cloud transcription services, or cloud storage clients.
  - No bypass flags or alternate code paths may skip preflight, DPIA, anchor integrity, lens lock, reviewer identity, verdict completion, or audit anchor checks.
  - Only `src/tools/review_cli.py` may write a non-null `human_verdict`; reviewer identity must be ORCID or institutional username; anonymous, null, and empty values are rejected.
  - Every governed artifact must include a valid `strand` value (`IPA`, `PDA`, `TA`, `quant`, or `mixed`).
  - Every LLM-produced artifact must record `model_config` with `model_name`, `temperature`, `seed`, `ollama_version`, and `prompt_hash`.
  - All artifact writes must use temp-then-rename; locked artifacts (Pass 1 outputs/anchors after anchor write, lens after `locked: true`, evidence reviews after verdict) are append-only — no silent overwrite or `--regenerate` flag.
  - `dataset_id` must be validated before use in file paths: reject `../`, `/`, `\`, null bytes, and characters outside `[a-zA-Z0-9_-]`; check for collisions before write; resolve to absolute paths within repo root; raw archives must never enter audit bundles.
  - Errors must use structured `[ERROR_CODE]` plus `Action:` output aligned with `docs/error_codes.md`.
  - Test and CI flows must run with `MOCK_LLM=true` and must not require a live model or network.
  - Secrets and credentials stay in `config/secrets.yaml` (gitignored) or environment variables; never committed.
## Why this system exists (north star)
- north_star: Make AI-assisted qualitative research ethically defensible, methodologically transparent, and auditable by enforcing governance in code rather than relying on researcher self-discipline.
## Data flow (sensitive data)
- data_flow:
  - Raw text or audio enters locally; audio transcription stays local-only; raw files are archived under `artifacts/raw_archive/` (gitignored); `special_category` sensitivity triggers a signed DPIA requirement before ingest and again before Pass 2.
  - De-identified analysis artifacts feed Pass 1; `pass1_output_*.json` is hashed into `pass1_anchor_*.json`; Pass 2 remains blocked until the anchor is upgraded from `local` to `osf_doi` or `repo_accession`.
  - Lens dialogue captures researcher responses, writes `lens_*.json`, and locks it with researcher signature (ORCID or institutional identity).
  - Pass 2 writes seeded and deterministic outputs plus `stability_report_*.json`; grounding writes `evidence_review_*.json` with `human_verdict: null`.
  - `review_cli.py` adds human verdicts, reviewer identity, and interpretive-proposition metadata; `audit_emitter.py` packages final artifacts and metadata; raw participant archives and direct cloud AI calls are never valid egress paths.
## Project Ethos
- project_ethos: Governance-first research engineering — preserve auditability, reflexivity, human accountability, and reproducibility even when that slows the happy path.
## Hard gates
- Preflight document gate | trigger: required workflow, lens, schema, or compliance files missing | effect: block startup (`ERR_PREFLIGHT_MISSING`, exit 1) | recovery: provide the required Markdown/JSON file or convert from `html-archive/` sources.
- DPIA gate | trigger: `special_category` sensitivity with missing or invalid `artifacts/dpia_signed.json` | effect: block ingest and Pass 2 (`ERR_DPIA_MISSING` / `ERR_DPIA_INVALID`, exit 2) | recovery: complete checklist, obtain DPO sign-off, save signed record.
- Pass 1 anchor integrity gate | trigger: missing anchor, hash mismatch, local-only anchor, or invalid anchor value | effect: block Pass 2 (`ERR_PASS1_ANCHOR_MISSING` / `ERR_PASS1_HASH_MISMATCH` / `ERR_PASS1_ANCHOR_LOCAL`, exit 3) | recovery: restore or re-run Pass 1, then complete approved external anchor upgrade.
- Lens lock gate | trigger: lens file missing, unlocked, incomplete, or unsigned | effect: block Pass 2 (`ERR_LENS_NOT_LOCKED` / `ERR_LENS_SIGNATURE_MISSING`, exit 4) | recovery: complete lens dialogue and lock with valid researcher identity.
- Strand gate | trigger: governed artifact missing `strand` field | effect: block downstream grounding or audit (`ERR_STRAND_MISSING`, exit 5) | recovery: add a valid strand label and re-run the affected stage.
- Human verdict completion gate | trigger: any evidence review has null verdict | effect: block audit emission (`ERR_VERDICT_INCOMPLETE`, exit 5) | recovery: complete `src/tools/review_cli.py` review for every pending claim.
- Audit anchor gate | trigger: audit packaging attempted while `anchor_type == local` | effect: block bundle emission (`ERR_ANCHOR_LOCAL_AT_BUNDLE`, exit 5) | recovery: upgrade Pass 1 anchor to approved external reference first.
## Prohibited integrations
- External model SDKs: `openai`, `anthropic`, `cohere`, `replicate`, `huggingface_hub` — violate local-only participant-data handling.
- Cloud transcription: `assemblyai`, `deepgram` — transmit sensitive audio to external servers.
- Orchestration frameworks: `langchain`, `llamaindex` — explicitly prohibited by repo policy.
- Cloud storage: `boto3`, `google-cloud-*` — incompatible with local-data governance.
- Hosted model-provider configurations for sensitive runs — not permitted for participant-data workflows.
## Artifact conventions
- Runtime artifacts write to `artifacts/`; raw participant archives to `artifacts/raw_archive/` (gitignored); examples to `examples/`; test fixtures to `tests/fixtures/`.
- Filenames: `deidentified_[participant_code]_[session].json`, `pass1_output_[dataset_id].json`, `pass1_anchor_[dataset_id].json`, `pass2_output_[label]_[dataset_id].json`, `stability_report_[dataset_id].json`, `claim_evidence_table_[dataset_id].json`, `evidence_review_[claim_id]_[dataset_id].json`, `audit_bundle_[run_id].zip` plus metadata JSON.
- SHA256 is the sole integrity hash; computed on write, stored in the anchor or manifest.
- LLM prompts live in `src/prompts/*.txt`; `prompt_hash` (SHA256 of the prompt file) must be recorded in LLM-generated artifacts alongside `model_config`.
- Locked artifacts are append-only after their lock point: no silent overwrite, no `--regenerate` or `--force-rewrite` flags permitted.