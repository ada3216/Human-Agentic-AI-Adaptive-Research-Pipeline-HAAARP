## What this system does
- project_summary: Executes a governance-first human–AI qualitative research pipeline that enforces blind Pass 1, reflexive lens capture, lens-informed Pass 2, per-claim grounding checks, mandatory human verdicts, and audit-bundle integrity controls before findings can be finalized.

## Who uses it and how
- users_and_context: Primary users are researchers/supervisors conducting psychotherapy or health-adjacent qualitative studies on local infrastructure. They run CLI stages in sequence, complete required human gates (lens dialogue, reviewer verdicts, DPIA/anchor obligations), and produce an auditable artifact bundle for supervision, examination, or deposit.

## Key Components
- `src/agent/orchestrator.py` (implemented): preflight + sequencing gatekeeper for staged execution.
- `src/modules/ingest_and_deid.py` (implemented/partial): raw archive ingest + de-identification and manual spot-check gate.
- `src/agent/pass1_runner.py` (implemented): blind first-pass analysis + local anchor emission.
- `src/modules/osf_uploader.py` (partial): anchor upgrade path from local to external reference.
- `src/modules/lens_dialogue.py` (implemented/partial): structured reflexivity capture and signed lock.
- `src/agent/pass2_runner.py` (implemented): hard-gated lens-informed Pass 2 and stability runs.
- `src/modules/grounding_checker.py` (implemented/partial): claim evidence verification and review-record generation.
- `src/tools/review_cli.py` (implemented): sole authority for human verdict assignment.
- `src/modules/audit_emitter.py` (implemented): packaging + synthesis gates + metadata generation.
- `src/schemas/*.json` (implemented): schema contracts for anchors, lens, DPIA, stability, evidence review.
- `tests/` (implemented): mocked governance/security/adversarial validation suite.

## Non-negotiable architectural patterns
- patterns:
  - All pipeline stages are fail-closed gates over append-only artifacts, with mandatory human decisions at lens lock and evidence verdict points.
  - Enforce two-pass method integrity: Pass 1 remains blind; Pass 2 is impossible without locked lens and externally upgraded anchor.
  - Keep all participant-data model processing local via Ollama/WhisperX paths.
  - Treat artifact generation as audit infrastructure: every core artifact carries strand metadata and SHA256-traceable lineage.

## Non-negotiable constraints
- constraints:
  - Do not introduce external LLM/transcription/cloud-storage dependencies for participant data paths (`openai`, `anthropic`, `langchain`, `assemblyai`, `deepgram`, `boto3`, `google-cloud-*`, etc.).
  - Do not programmatically set `human_verdict` outside `src/tools/review_cli.py`.
  - Do not bypass Pass 2 gates (`--skip-checks`, force flags, local-anchor acceptance).
  - Do not bypass DPIA gate for `special_category` sensitivity.
  - Keep prompts in `src/prompts/*.txt`; do not hardcode prompt bodies in Python modules.
  - Use structured errors aligned to `docs/error_codes.md`; avoid bare exception-style governance failures.
  - Enforce reviewer identity semantics (ORCID/institutional username; no anonymous verdict attribution).

## Why this system exists (north star)
- north_star: This project solves the reliability and ethics gap in AI-assisted qualitative psychotherapy research by turning governance requirements into enforceable pipeline gates for researchers and supervisors. It serves teams who need local-only processing, auditable reproducibility, and explicit human adjudication instead of black-box automation. Success means a study can run end-to-end with no gate bypass, no unauthorized data egress, complete reviewer-attributed evidence verdicts, and a defensible audit bundle that an examiner can independently verify.

## Data flow (sensitive data)
- data_flow:
  - Interview/session data enters via local files into ingest/transcribe modules.
  - De-identified artifacts are processed locally through Ollama (and optional local WhisperX) only.
  - Raw source files remain in local archive and are never included in audit bundles.
  - Governed outputs are stored in local `artifacts/` with hash-tracked records and human-review gates.
  - Limited external export is allowed only for governance anchors/bundles to approved repositories (OSF or institutional) after required gating.
  - Deletion/retention is managed by researcher/institution policy and is outside current automated enforcement.

## Project Ethos
- project_ethos: Governance-first, fail-closed, human-accountable research engineering where reproducibility and ethical defensibility take priority over throughput or automation convenience.

## Hard gates
- Pass 2 anchor existence | trigger: missing `pass1_anchor_[dataset_id].json` | effect: block | recovery: run Pass 1 and generate anchor
- Pass 1 hash integrity | trigger: stored hash != file SHA256 | effect: block | recovery: restore trusted Pass 1 artifact or rerun Pass 1
- External anchor upgrade | trigger: `anchor_type == local` at Pass 2 or bundle emission | effect: block | recovery: deposit and update anchor via uploader/manual accession
- Lens lock gate | trigger: lens missing or `locked != true` | effect: block | recovery: complete lens dialogue and lock
- Lens signature gate | trigger: null/invalid researcher signature | effect: block | recovery: lock lens with ORCID/institutional ID
- DPIA gate | trigger: `special_category` without valid signed DPIA | effect: block | recovery: provide approved `artifacts/dpia_signed.json`
- Human verdict completion gate | trigger: any `human_verdict` null at bundle stage | effect: block | recovery: complete `review_cli.py` adjudication
- Strand completeness gate | trigger: required artifact missing `strand` | effect: block | recovery: correct artifact generation and rerun affected stage

## Prohibited integrations
- OpenAI/Anthropic/Cohere/Replicate/HuggingFace inference APIs: violate local-only participant-data processing constraint.
- LangChain/LlamaIndex orchestration in participant-data path: introduces non-required abstraction and external-service drift risk.
- Cloud transcription services (AssemblyAI/Deepgram): prohibited for sensitive-data egress reasons.
- Cloud storage SDKs (`boto3`, `google-cloud-*`) in governed data path: violate local handling guarantees.

## Artifact conventions
- `pass1_output_[dataset_id].json` and `pass1_anchor_[dataset_id].json` establish first-pass integrity baseline.
- `lens_[run_id].json` is locked/signed before Pass 2 and treated as immutable after lock.
- `pass2_output_[label]_[dataset_id].json` captures seeded + deterministic positioned runs.
- `evidence_review_[claim_id]_[dataset_id].json` is created with `human_verdict: null`; populated only through review CLI.
- `audit_bundle_[run_id].zip` + metadata JSON carry manifest hashes, reviewer IDs, stability metrics, and interpretive-proposition traceability.
