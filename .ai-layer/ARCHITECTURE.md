# Architecture

## What this system does

project_summary: A modular, locally-executed research pipeline for AI-assisted qualitative psychotherapy research. Ethical and methodological safeguards are enforced at the infrastructure level — not left to researcher self-discipline. The pipeline implements two-pass locked analysis (blind Pass 1 cryptographically anchored before theoretically-positioned Pass 2), structured reflexivity elicitation, per-claim grounding verification with human evidence review, DPIA gating for special-category data, and audit bundle generation with full artifact hash chains.

## Who uses it and how

users_and_context: Qualitative researchers (masters, PhD, lab teams) conducting psychotherapy or health-related studies. Researchers interact via CLI (`orchestrator.py`, `review_cli.py`, `lens_dialogue.py`). Supervisors verify audit bundles and handover checklists. The pipeline runs entirely on the researcher's local machine via Ollama; no cloud interaction except optional OSF deposit for governance anchors.

## Key Components

- orchestrator (`src/agent/orchestrator.py`): Sequences the 8 pipeline stages with hard gate checks at each transition — implemented
- pass1_runner (`src/agent/pass1_runner.py`): Runs blind (no-context) Pass 1 analysis, writes output + anchor — implemented
- pass2_runner (`src/agent/pass2_runner.py`): Runs lens-informed Pass 2 with 4 stability reruns; enforces 6 gate preconditions — implemented
- lens_dialogue (`src/modules/lens_dialogue.py`): 10-question structured reflexivity interview, produces lockable lens record — implemented
- grounding_checker (`src/modules/grounding_checker.py`): Per-claim evidence verification with support-strength ratings; writes `human_verdict: null` — implemented
- review_cli (`src/tools/review_cli.py`): Human-only verdict entry; the sole process that may set `human_verdict` to non-null — implemented
- audit_emitter (`src/modules/audit_emitter.py`): Validates all governance conditions and packages the final audit bundle ZIP — implemented
- dpia_gate (`src/modules/dpia_gate.py`): Hard block on special-category data ingestion without signed DPIA — implemented
- ollama_client (`src/modules/ollama_client.py`): Local-only LLM interface with MOCK_LLM support for testing — implemented
- osf_uploader (`src/modules/osf_uploader.py`): Upgrades anchor_type from local to osf_doi/repo_accession after external deposit — implemented
- ingest_and_deid (`src/modules/ingest_and_deid.py`): Archives raw data and applies de-identification — implemented
- transcribe_adapter (`src/modules/transcribe_adapter.py`): WhisperX local-only transcription adapter — implemented

## Non-negotiable architectural patterns

patterns:
  - All pipeline stages are fail-closed gates over append-only artifacts, with mandatory human decisions at lens lock and evidence verdict points.
  - All LLM calls go through `src/modules/ollama_client.py` to `http://localhost:11434` — no other LLM endpoint is permitted.
  - All artifact writes use temp-then-rename atomic pattern to prevent partial writes being hashed.
  - All errors use structured codes from `docs/error_codes.md` with code, message, and action — never bare `Exception()`.
  - System prompts live in `src/prompts/` as `.txt` files read from disk at runtime — never inline in Python source.
  - SHA256 is computed on write, not on read, and stored alongside the artifact.
  - Every output artifact carries a `strand` field (IPA/PDA/TA/quant/mixed) validated by audit emitter.
  - `model_config` block (model_name, temperature, seed, ollama_version, prompt_hash) is required in all LLM output artifacts.

## Non-negotiable constraints

constraints:
  - No participant data may be sent to any external API or cloud service at any stage (GDPR Article 9 legal constraint).
  - `human_verdict` may only be set by `review_cli.py` through human keyboard input — no programmatic bypass, no auto-accept flag.
  - Pass 2 cannot run unless all 6 gate conditions pass: anchor exists, hash matches, anchor_type is osf_doi or repo_accession (not local), lens exists, lens locked, researcher_signature non-null.
  - If sensitivity is special_category, DPIA gate blocks all data ingestion until `artifacts/dpia_signed.json` is present with `dpo_sign_off.decision == "approved"`.
  - Locked artifacts (pass1_output after anchor, pass1_anchor after OSF deposit, lens after lock, evidence_review after verdict) must not be modified or overwritten without explicit user instruction and audit trail.
  - `reviewer_id` must be ORCID or institutional username — null, empty, anonymous, or whitespace rejected.
  - `dataset_id` must match `[a-zA-Z0-9_-]` only — reject `../`, `/`, `\`, null bytes. Check path containment within repo root before writing.
  - Raw participant data (`artifacts/raw_archive/`) must never appear in audit bundle ZIP.
  - All tests run with MOCK_LLM=true, no network access, no live model. Tests must not mock gate checks themselves — they exercise actual gate logic.
  - No dependency may be added to `requirements.txt` without explicit user confirmation.

## Why this system exists (north star)

north_star: This project solves the reliability and ethics gap in AI-assisted qualitative psychotherapy research by turning governance requirements into enforceable pipeline gates for researchers and supervisors. It serves teams who need local-only processing, auditable reproducibility, and explicit human adjudication instead of black-box automation. Success means a study can run end-to-end with no gate bypass, no unauthorized data egress, complete reviewer-attributed evidence verdicts, and a defensible audit bundle that an examiner can independently verify.

## Data flow (sensitive data)

data_flow:
  - Interview/session recordings and transcripts enter via local files into ingest_and_deid module; raw source archived in `artifacts/raw_archive/` (gitignored).
  - De-identified artifacts are processed locally through Ollama (and optional local WhisperX) only — no external API calls.
  - Raw source files remain in local archive and are never included in audit bundles or committed to git.
  - Governed outputs (pass1_output, pass2_output, lens records, evidence reviews) are stored in `artifacts/` with SHA256-tracked records and human-review gates.
  - Limited external export is allowed only for governance anchors and audit bundles to approved repositories (OSF or institutional) after required gating (OSF deposit for pass1 anchor, all verdicts complete for audit bundle).
  - Credentials (OSF token) go in `config/secrets.yaml` (gitignored) or environment variables — never committed.
  - Deletion/retention of participant data is managed by researcher/institution policy and is outside current automated enforcement.

## Project Ethos

project_ethos: Governance is infrastructure, not policy. Every methodological safeguard (two-pass lock, human verdict, DPIA gate, strand labelling, artifact immutability) is enforced by code that fails closed, not by trust that researchers will follow instructions. The pipeline optimises for auditability, reproducibility, and defensibility over convenience.

## Hard gates

| Gate | Trigger | Effect | Recovery |
|---|---|---|---|
| DPIA gate | `sensitivity == "special_category"` and `artifacts/dpia_signed.json` absent or invalid | Block — `sys.exit(2)` | Complete DPIA checklist, obtain DPO approval, save signed record |
| Pass-1 anchor gate | `pass1_anchor_[dataset_id].json` does not exist before Pass 2 | Block — `sys.exit(3)` | Run Pass 1 first |
| Hash-match gate | SHA256 of `pass1_output` does not match stored `pass1_hash` in anchor | Block — `sys.exit(3)` | Re-run Pass 1 or investigate tampering |
| OSF-deposit gate | `anchor_type == "local"` when Pass 2 or audit bundle is attempted | Block — `sys.exit(3)` or `sys.exit(5)` | Deposit pass1_output to OSF, run `osf_uploader.py` to upgrade anchor_type |
| Lens-lock gate | `lens.locked != true` or `researcher_signature` is null before Pass 2 | Block — `sys.exit(4)` | Lock lens with valid ORCID/institutional signature |
| Verdict-complete gate | Any `evidence_review` has `human_verdict: null` when audit bundle is attempted | Block — `sys.exit(5)` | Complete all verdicts via `review_cli.py` |

## Prohibited integrations

- `openai`: Cloud API — sends data to OpenAI servers
- `anthropic`: Cloud API — sends data to Anthropic servers
- `langchain`: Abstraction layer for cloud APIs; adds unnecessary complexity
- `llamaindex`: Cloud-oriented orchestration framework
- `assemblyai`: Cloud transcription — sends audio to external servers
- `deepgram`: Cloud transcription — same reason
- `boto3` / `google-cloud-*`: Cloud storage — participant data must not leave local machine
- `cohere`: Cloud API
- `replicate`: Cloud API
- `huggingface_hub`: Sends model requests to HuggingFace servers by default

## Artifact conventions

- All pipeline-generated artifacts are written to `artifacts/`
- Naming: `pass1_output_[dataset_id].json`, `pass2_output_[label]_[dataset_id].json`, `pass1_anchor_[dataset_id].json`, `lens_[run_id].json`, `evidence_review_[claim_id]_[dataset_id].json`
- Raw participant data in `artifacts/raw_archive/` — gitignored, never in audit bundle
- Example/synthetic artifacts for CI in `examples/`
- Test fixtures in `tests/fixtures/`
- All writes use temp-then-rename atomic pattern
- SHA256 computed on every artifact write, stored in anchor or manifest
- Locked artifacts may not be overwritten without explicit user instruction
- OSF anchor validation: `osf_doi` must match `^https://osf\.io/[a-z0-9]{5,}`, `repo_accession` must start with `https://`
