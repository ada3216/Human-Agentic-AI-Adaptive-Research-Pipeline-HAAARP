# Research Pipeline Guardrails — Complete Reference (v1, Phases 0–6)

**Scope:** This document is self-contained. No other guardrails file is required alongside it. An executor agent reading only this document and `Agentic_Pipeline_Dev_Plan_v2_1.md` has everything needed to operate correctly.

**Companion spec:** `Agentic_Pipeline_Dev_Plan_v2_1.md` — Agentic Human–AI Research Pipeline Phased Development Plan (Version 2.1)

---

## Notation Key

| Symbol | Meaning |
|--------|---------|
| 🛑 **HARD STOP** | Execution must halt; no work proceeds until condition is resolved |
| 🚫 **HARD RULE** | Non-negotiable; no agent discretion permitted |
| ⚠️ **ADVISORY** | Shown in output; does not block unless escalated |
| 🔑 **HUMAN GATE** | Requires explicit human action before the pipeline may continue |
| 🔓 **OVERRIDE** | No automatic override exists for immutable blocks; all bypasses are human-only |

---

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [Pre-Flight Classification](#2-pre-flight-classification)
3. [Sensitivity Classification](#3-sensitivity-classification)
4. [Phase Order and Dependency Rules](#4-phase-order-and-dependency-rules)
5. [Absolute Rules (COPILOT_INSTRUCTIONS)](#5-absolute-rules-copilot_instructions)
6. [Human Gates](#6-human-gates)
7. [Pass Sequencing Controls](#7-pass-sequencing-controls)
8. [DPIA Gate Controls](#8-dpia-gate-controls)
9. [Data Handling and Local-Only Constraint](#9-data-handling-and-local-only-constraint)
10. [Human Verdict Controls](#10-human-verdict-controls)
11. [Artifact Integrity Controls](#11-artifact-integrity-controls)
12. [Reviewer Identity Controls](#12-reviewer-identity-controls)
13. [Strand Label Controls](#13-strand-label-controls)
14. [Error Handling Controls](#14-error-handling-controls)
15. [Secrets and Credential Controls](#15-secrets-and-credential-controls)
16. [Audit Bundle Controls](#16-audit-bundle-controls)
17. [Testing and CI Controls](#17-testing-and-ci-controls)
18. [Prompt Integrity Controls](#18-prompt-integrity-controls)
19. [Interpretive Proposition Controls](#19-interpretive-proposition-controls)
20. [Override Mechanisms](#20-override-mechanisms)
21. [Quick-Reference Table — All Hard Stops](#21-quick-reference-table--all-hard-stops)

- [§A — Pass Sequencing Hard Stops](#a--pass-sequencing-hard-stops)
- [§B — DPIA and Governance Hard Stops](#b--dpia-and-governance-hard-stops)
- [§C — Audit and Synthesis Hard Stops](#c--audit-and-synthesis-hard-stops)
- [§D — Data Integrity Hard Stops](#d--data-integrity-hard-stops)
- [§E — All Hard Stops Quick Reference](#e--all-hard-stops-quick-reference)

---

## 1. Philosophy

The research pipeline guardrail system exists to protect the methodological integrity, participant privacy, and epistemic honesty of qualitative and mixed-methods research conducted with AI assistance. Its core principles are:

**Fail closed over fail open.** When any control cannot verify its conditions — anchor absent, DPIA missing, verdict incomplete, strand field null — the default answer is to block, not to proceed. A blocked pipeline run can be recovered; a pipeline that proceeds through a compromised gate produces invalid research output that cannot be un-run.

**Human checkpoints are non-delegable where they protect methodological integrity.** The researcher must complete the lens dialogue. The researcher must set evidence verdicts. The researcher must sign and lock the lens. No AI process may substitute for these human actions under any circumstances.

**Local-only is a DPIA constraint, not a preference.** The prohibition on sending data to external APIs or cloud services exists because the pipeline is designed to handle special category health and therapy data. This constraint is enforced by the DPIA and BPS ethics guidelines. It is not a configuration option that can be toggled off.

**Immutable controls are unconditional.** The DPIA gate, the Pass 2 anchor check, the human-verdict non-delegation rule, and the local-only constraint apply regardless of study level, configuration, or agent discretion. They cannot be treated as warnings or advisories.

**The agent is a participant, not an authority.** All AI-generated output is subject to human review before it enters the audit record. The agent surfaces flags, computes metrics, and writes draft output — it does not approve, validate, or finalise research conclusions. Grounding verification identifies concerns; humans resolve them.

**Every block has a recovery path.** Each hard stop corresponds to a structured error code in `docs/error_codes.md`. Every error carries an `Action:` string telling the researcher exactly what to do next. Bare exceptions, silent failures, and unstructured error output are prohibited.

---

## 2. Pre-Flight Classification

🚫 **HARD RULE:** The agent MUST read `COPILOT_INSTRUCTIONS.md` before touching any file in the repository. If `COPILOT_INSTRUCTIONS.md` does not yet exist, the agent must create it as the very first action in Phase 0, before any other task.

🛑 **HARD STOP:** The following five documents must be present as Markdown or JSON files before Phase 0 proceeds. If any are missing, the agent must halt and print `[ERR_PREFLIGHT_MISSING]` with the specific missing path and action string.

| Required File | Format | Description |
|---|---|---|
| `docs/workflow.md` | Markdown | Main pipeline spec (8-stage agentic workflow) |
| `docs/lens.md` | Markdown | Lens dialogue questions (10 Qs) + guidance |
| `artifacts/audit_schema.json` | JSON | Audit metadata JSON schema |
| `artifacts/dpia_checklist.md` | Markdown | DPIA submission template |
| `artifacts/consent_snippets.md` | Markdown | Consent language templates |

🚫 **HARD RULE:** HTML exports of required documents are not sufficient. The agent reads Markdown. If only HTML versions are present, the agent must halt and instruct the researcher to convert them before proceeding:
```
pandoc docs/workflow.html -o docs/workflow.md
```

🚫 **HARD RULE:** The agent must never create the five pre-flight documents. They are human-authored documents from the research design process. Creating them would constitute fabrication of research governance records.

---

## 3. Sensitivity Classification

🚫 **HARD RULE:** Every pipeline run MUST carry a `sensitivity` value in `config/defaults.yaml`. Valid values: `public_text`, `personal_non_sensitive`, `special_category`.

| Sensitivity Level | Applies When | DPIA Required |
|---|---|---|
| `public_text` | Data is publicly available; no participant identification risk | No |
| `personal_non_sensitive` | Personal data; not health, therapy, or special category | No (recommended) |
| `special_category` | Health, therapy, or other GDPR Article 9 category data | **Yes — hard block** |

🛑 **HARD STOP:** If `sensitivity == special_category` and `artifacts/dpia_signed.json` is absent, the pipeline MUST block ingestion immediately. Exit code: 2. Error: `ERR_DPIA_MISSING`. This check applies at ingestion (Phase 2a) and at Pass 2 entry (Phase 2b).

🚫 **HARD RULE:** `sensitivity: normal` is not a valid value. If present in config, the agent must halt with `ERR_SENSITIVITY_UNKNOWN` and instruct the researcher to correct it.

⚠️ **ADVISORY:** If `sensitivity == personal_non_sensitive`, a DPIA is recommended but not blocking. The agent should print a reminder that a DPIA may be required under institutional policy.

---

## 4. Phase Order and Dependency Rules

🚫 **HARD RULE:** Phases must execute in the order defined in the dev plan. Phase 2b requires all Phase 2a artifacts. Phase 3 requires all Phase 2a and 2b modules. Phase 4 requires Phase 3 validation passing.

🛑 **HARD STOP:** Pass 2 (`pass2_runner.py`) must not be invoked unless ALL of the following are true:

| Condition | Error if False | Exit Code |
|---|---|---|
| `artifacts/pass1_anchor_[dataset_id].json` exists | `ERR_PASS1_ANCHOR_MISSING` | 3 |
| Stored `pass1_hash` matches SHA256 of `pass1_output` file | `ERR_PASS1_HASH_MISMATCH` | 3 |
| `anchor_type` is NOT `"local"` | `ERR_PASS1_ANCHOR_LOCAL` | 3 |
| `lens_[run_id].json` exists AND `locked == true` | `ERR_LENS_NOT_LOCKED` | 4 |
| `lens.researcher_signature` is non-null | `ERR_LENS_SIGNATURE_MISSING` | 4 |
| If `special_category`: `artifacts/dpia_signed.json` exists | `ERR_DPIA_MISSING` | 2 |

🚫 **HARD RULE:** The audit emitter (`audit_emitter.py`) must not package a bundle if `pass1_anchor_type == "local"`. The OSF deposit step (Step 4 of the runbook) upgrades this from `local` to `osf_doi` or `repo_accession`. A local anchor means the audit trail is not externally verifiable.

---

## 5. Absolute Rules (COPILOT_INSTRUCTIONS)

The following rules are sourced directly from `COPILOT_INSTRUCTIONS.md` and the "Developer notes — absolute rules" section of the dev plan. They apply unconditionally at every phase.

**AR-1 — No secrets committed.**
🚫 **HARD RULE:** Credentials, tokens, and API keys must never appear in committed files. Write `config/secrets.example.yaml` with placeholder keys. All runtime credentials go via environment variables or the gitignored `config/secrets.yaml`. The agent must never suggest committing a token or key.

**AR-2 — Two-pass lock is enforced in code.**
🚫 **HARD RULE:** The two-pass lock is not a matter of trust or convention — it is enforced programmatically. Pass 2 cannot run unless all six conditions in §4 are satisfied. No advisory, warning, or override exists for this block.

**AR-3 — DPIA gate is a hard code block.**
🚫 **HARD RULE:** If `sensitivity == special_category`, check for `artifacts/dpia_signed.json` before ingesting any data. If absent: print `ERR_DPIA_MISSING` with action string and call `sys.exit(2)`. Never raise a bare Exception.

**AR-4 — Local-only processing.**
🚫 **HARD RULE:** All AI processing must run on the researcher's own machine. No data may be sent to external APIs or cloud services at any stage. Use WhisperX for transcription (local only). Use Ollama REST API for LLM calls. Do not use LangChain, AssemblyAI, or any cloud-hosted model API.

**AR-5 — Artifact naming conventions.**
🚫 **HARD RULE:** Always write generated artifacts to `artifacts/`. Always compute SHA256 on write. De-identified output files must be named `deidentified_[participant_code]_[session].json`. Analysis agents must only accept files matching this naming pattern.

**AR-6 — OSF deposit before Pass 2.**
🚫 **HARD RULE:** `anchor_type: local` is only valid immediately after Pass 1 completes. It must be upgraded to `osf_doi` or `repo_accession` before Pass 2 is allowed to run. The audit emitter also refuses to package if `anchor_type` is still local.

**AR-7 — Human verdicts are non-delegable.**
🚫 **HARD RULE:** `grounding_checker.py` only writes `evidence_review_*.json` with `human_verdict: null`. `review_cli.py` is the only place verdicts may be set. No AI process, under any circumstances, may set `human_verdict` to a non-null value.

**AR-8 — Strand labels are required on every artifact.**
🚫 **HARD RULE:** Valid values: `IPA`, `PDA`, `TA`, `quant`, `mixed`. Audit emitter validates this before packaging and exits with `ERR_STRAND_MISSING` (code 5) if any artifact is missing it. The agent must include a `strand` field instruction in all AI output prompts.

**AR-9 — All errors use structured codes.**
🚫 **HARD RULE:** Format: `[ERROR_CODE] message\nAction: what to do`. Never raise a bare `Exception()` or print plain text errors. All codes, messages, actions, and exit values are defined in `docs/error_codes.md`.

**AR-10 — All CLI tools exit with shell return codes.**
🚫 **HARD RULE:** `0` = success. `1–5` = specific failure types as defined in `docs/error_codes.md`. This enables CI and shell scripting to detect failures cleanly.

**AR-11 — Reviewer identity is required.**
🚫 **HARD RULE:** `reviewer_id` must be an ORCID (`https://orcid.org/...`) or institutional username. Anonymous or null `reviewer_id` must be rejected by `review_cli.py`. The audit bundle must include the `reviewer_ids` list.

**AR-12 — Extract prompts from docs, never invent them.**
🚫 **HARD RULE:** Lens questions must be extracted verbatim from `docs/lens.md`. Pass 1 and Pass 2 system prompts must be derived from `docs/workflow.md`. If these documents are missing, halt with `ERR_PREFLIGHT_MISSING` — do not invent prompt content.

**AR-13 — Testing uses mocks only.**
🚫 **HARD RULE:** All 14 named tests must pass with `MOCK_LLM=true`. Tests must run with no network access and no live model. CI must never commit secrets or make live model calls.

---

## 6. Human Gates

Human gates are points in the pipeline where execution must pause and wait for explicit human action. Unlike autonomy-level controls in other agentic systems, these gates are not reducible — they cannot be bypassed at any configuration level.

**HG-1 — Pre-flight document provision.**
🔑 **HUMAN GATE:** The five pre-flight documents must be provided by the researcher before Phase 0 begins. The agent must not create them. If missing, the agent halts and surfaces the missing paths with instructions.

**HG-2 — De-identification spot check.**
🔑 **HUMAN GATE:** `ingest_and_deid.py` must call `spot_check_prompt()` after de-identification. This function prints a formatted notice and blocks until the researcher types `confirmed`. This gate is not automated — it requires an explicit terminal interaction.

**HG-3 — OSF deposit after Pass 1.**
🔑 **HUMAN GATE:** After `pass1_runner.py` completes, `prompt_osf_deposit()` must print OSF deposit instructions and block until the researcher confirms the deposit is complete. The agent must not auto-proceed to Pass 2 without this confirmation. If no OSF token is available, the researcher must upload manually and enter the DOI via CLI prompt.

**HG-4 — Lens dialogue completion.**
🔑 **HUMAN GATE:** `lens_dialogue.py` presents all 10 questions to the researcher via `stdout` input prompts. The researcher types responses — the AI does not generate answers to the reflexivity questions. All 10 questions must be answered before `lock_lens()` may be called.

**HG-5 — Lens locking with researcher signature.**
🔑 **HUMAN GATE:** `lock_lens()` requires `researcher_id` (ORCID preferred; institutional username accepted). If `researcher_id` is null or empty, exit with code 4 (`ERR_LENS_SIGNATURE_MISSING`). The researcher must provide their ID — the agent may not generate or invent a signature value.

**HG-6 — Human evidence review.**
🔑 **HUMAN GATE:** `review_cli.py` is a terminal CLI that presents each claim with `human_verdict: null` to the researcher for verdict. This tool must not be bypassed, automated, or run silently. All verdicts must be set by a human before the audit bundle may be emitted.

**HG-7 — DPIA sign-off.**
🔑 **HUMAN GATE:** For `special_category` data, `artifacts/dpia_signed.json` must be produced by the Data Protection Officer (or equivalent). This document must contain: `dpo_name`, `signature_date`, `decision: approved`. The agent validates presence and required fields but cannot create or approve the DPIA itself.

---

## 7. Pass Sequencing Controls

🚫 **HARD RULE (PS-1):** Pass 1 must run with a system prompt containing no researcher lens and no theoretical framing. The prompt must explicitly state that the AI has not been given any theoretical frame or researcher hypotheses.

🚫 **HARD RULE (PS-2):** Pass 1 output must include a `strand` field. Strand must be one of: `IPA`, `PDA`, `TA`, `quant`, `mixed`.

🚫 **HARD RULE (PS-3):** `pass1_anchor_[dataset_id].json` must be written immediately after Pass 1 completes, with `anchor_type: local`. This anchor must contain: `pass1_hash`, `artifact_path`, `timestamp_utc`, `operator_id`, `pre_registration_doi`, `strand`, `anchor_type`, `anchor_value`.

⚠️ **ADVISORY (PS-4):** If `pre_registration_doi` is null in the anchor, log `ERR_PREREG_MISSING` as a soft warning. This does not block Pass 1 or Pass 2 — but the absence will be flagged in the audit bundle.

🚫 **HARD RULE (PS-5):** Pass 2 must inject `lens_summary` from the locked lens JSON into the system prompt. It must not proceed with a default or empty lens context.

🚫 **HARD RULE (PS-6):** Pass 2 must include a disconfirmation mandate in its system prompt — the AI must be explicitly instructed to surface material that resists or complicates the researcher's lens.

🚫 **HARD RULE (PS-7):** Stability testing is mandatory. Pass 2 must run four times: seeds 42, 99, 123, and a deterministic run (`temperature=0.0`). A `stability_report_[dataset_id].json` containing `theme_stability_score`, `jaccard_mean`, `lens_amplification_index`, and `unstable_themes` must be produced before the pipeline proceeds to grounding verification.

---

## 8. DPIA Gate Controls

🛑 **HARD STOP (DG-1):** If `sensitivity == special_category` and `artifacts/dpia_signed.json` is absent: print `ERR_DPIA_MISSING` with action string and `sys.exit(2)`. This check occurs at ingestion and again at Pass 2 entry.

🛑 **HARD STOP (DG-2):** If `dpia_signed.json` exists but is missing required fields (`dpo_name`, `signature_date`, `decision: approved`): print `ERR_DPIA_INVALID` and `sys.exit(2)`.

🚫 **HARD RULE (DG-3):** The DPIA gate must be implemented as a hard code block in `src/modules/dpia_gate.py` — not a warning, not a log message, not a soft check. The file either passes validation and returns, or it calls `sys.exit(2)`.

🚫 **HARD RULE (DG-4):** `dpia_gate.py` must be invoked before any participant data enters the AI processing pipeline, regardless of which module initiates ingest. The gate check is not optional even if the caller believes the data is already de-identified.

---

## 9. Data Handling and Local-Only Constraint

🚫 **HARD RULE (LO-1):** All model inference must use the local Ollama REST API (`POST http://localhost:11434/api/generate`). No call to any external hosted model API is permitted for any pipeline stage that handles participant data.

🚫 **HARD RULE (LO-2):** Transcription must use WhisperX running locally. AssemblyAI and any cloud transcription service are explicitly prohibited. Any suggestion to use a cloud transcription API is a DPIA violation for special category data.

🚫 **HARD RULE (LO-3):** The `participant_code_map` (mapping real participant names to codes) must never be written to any file that is included in AI inputs. It must be stored separately. Analysis agents must only accept files with the naming pattern `deidentified_[participant_code]_[session].json`.

🚫 **HARD RULE (LO-4):** `config/secrets.yaml` must be gitignored at all times. The `.gitignore` must cover: `config/secrets.yaml`, `*.env`, `artifacts/raw_archive/`, `*_participant_code_map.json`.

🚫 **HARD RULE (LO-5):** The `model.provider` field in `config/defaults.yaml` must be `local`. If a hosted provider value is present, the agent must treat this as a configuration error and halt with a structured error before any pipeline stage runs. This is not a preference check — the local-only constraint is a hard constraint enforced by DPIA, as stated in the dev plan key policy anchors. No advisory, warning, or researcher-confirmation flow is sufficient.

---

## 10. Human Verdict Controls

🚫 **HARD RULE (HV-1):** `grounding_checker.py` must write all `evidence_review_*.json` files with `human_verdict: null`. This is the only permitted initial state. No AI process may infer, guess, or fill in a verdict value.

🚫 **HARD RULE (HV-2):** `review_cli.py` is the sole authorised mechanism for setting `human_verdict` to a non-null value. No other module, script, or agent may write to the `human_verdict` field.

🛑 **HARD STOP (HV-3):** If any `evidence_review_*.json` file has `human_verdict: null` at the time `audit_emitter.py` is invoked: print `ERR_VERDICT_INCOMPLETE` and `sys.exit(5)`. The audit bundle must not be emitted with incomplete verdicts.

🚫 **HARD RULE (HV-4):** `grounding_checker.py` must not modify claim text. The `claim_text` field in every `evidence_review_*.json` must match the corresponding `claim_text` in `pass2_output` exactly. Modification of claims is a research integrity violation.

🚫 **HARD RULE (HV-5):** Verdicts of `accept_with_revision` must include `revised_claim_text` AND `notes`. Verdicts of `reject` must include `notes`. `review_cli.py` must enforce this and re-prompt if required fields are absent.

---

## 11. Artifact Integrity Controls

🚫 **HARD RULE (AI-1):** SHA256 must be computed and recorded for every generated artifact at the time of writing. This applies to: `pass1_output`, `pass2_output` files, `lens_[run_id].json`, and the `audit_bundle_[run_id].zip`.

🛑 **HARD STOP (AI-2):** If the stored `pass1_hash` in `pass1_anchor_[dataset_id].json` does not match the SHA256 of the `pass1_output` file at the time Pass 2 is invoked: print `ERR_PASS1_HASH_MISMATCH` and `sys.exit(3)`. The agent must not attempt to re-hash or repair the anchor — this is a human recovery action.

🚫 **HARD RULE (AI-3):** `artifacts/repo_manifest.json` must be written in Phase 0 with SHA256 for each of the five pre-flight documents. This manifest is the baseline integrity record for the repository.

🚫 **HARD RULE (AI-4):** The `lens_hash` recorded in the audit bundle must be the SHA256 of the complete locked lens file, including the `researcher_signature` field. A hash computed before signing is invalid. Note: `pass1_anchor` does not contain `lens_hash` — it contains only `pass1_hash`. The `lens_hash` is computed by `lock_lens()` and appears in the audit bundle metadata only.

---

## 12. Reviewer Identity Controls

🚫 **HARD RULE (RI-1):** `reviewer_id` must be an ORCID in the form `https://orcid.org/...` or an institutional username. `review_cli.py` must reject null, empty, or purely anonymous values at the point of entry.

🚫 **HARD RULE (RI-2):** `reviewer_id` must be read from the `REVIEWER_ID` environment variable. If absent, `review_cli.py` must prompt for it interactively. The agent must not generate, invent, or default a reviewer ID.

🚫 **HARD RULE (RI-3):** The audit bundle must include a `reviewer_ids` list containing all ORCID/usernames of humans who set verdicts during the review session. Anonymous review is not permitted; it is a research integrity concern.

🚫 **HARD RULE (RI-4):** `reviewer_role` must be one of: `researcher`, `supervisor`, `team_member`. Unrecognised roles must be rejected.

---

## 13. Strand Label Controls

🚫 **HARD RULE (SL-1):** Valid strand values are: `IPA`, `PDA`, `TA`, `quant`, `mixed`. Every output artifact must carry a `strand` field with one of these values. The `study.strand` field in `config/defaults.yaml` is required and indexed.

🛑 **HARD STOP (SL-2):** If any artifact presented to `audit_emitter.py` is missing the `strand` field: print `ERR_STRAND_MISSING` and `sys.exit(5)`. Packaging is blocked.

🚫 **HARD RULE (SL-3):** Pass 1 and Pass 2 system prompts must contain an explicit instruction to include a `strand` field in all JSON output. This is the point of enforcement — if the prompt does not require it, downstream artifacts will be missing it.

🚫 **HARD RULE (SL-4):** `grounding_checker.py` must exit with code 5 if the `strand` field is missing from any claim in `pass2_output`. Strand absence in Pass 2 output is a packaging blocker, not a runtime warning.

---

## 14. Error Handling Controls

🚫 **HARD RULE (EH-1):** All pipeline errors must use the structured format:
```
[ERROR_CODE] Description
Action: What the researcher should do next.
```
Bare `Exception()` raises and unformatted `print()` error messages are prohibited in all pipeline modules.

🚫 **HARD RULE (EH-2):** All error codes, messages, action strings, and exit codes must be defined in `docs/error_codes.md`. Adding a new error to a module requires adding it to `docs/error_codes.md` first.

🚫 **HARD RULE (EH-3):** Shell return codes are standardised:

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | `ERR_PREFLIGHT_MISSING` or `ERR_SENSITIVITY_UNKNOWN` (configuration error) |
| 2 | `ERR_DPIA_MISSING` or `ERR_DPIA_INVALID` (governance block) |
| 3 | `ERR_PASS1_ANCHOR_MISSING`, `ERR_PASS1_HASH_MISMATCH`, or `ERR_PASS1_ANCHOR_LOCAL` |
| 4 | `ERR_LENS_NOT_LOCKED` or `ERR_LENS_SIGNATURE_MISSING` |
| 5 | `ERR_VERDICT_INCOMPLETE` or `ERR_STRAND_MISSING` (synthesis block) |

🚫 **HARD RULE (EH-4):** `review_cli.py` must exit with code 0 if all verdicts are complete, or code 5 if verdicts remain. The calling pipeline must check this exit code before proceeding to audit emission.

---

## 15. Secrets and Credential Controls

🚫 **HARD RULE (SC-1):** `config/secrets.yaml` is gitignored. The agent must never write a token, API key, or password to any non-gitignored file, and must never commit such a file.

🚫 **HARD RULE (SC-2):** `config/secrets.example.yaml` must contain placeholder keys and instructions for the researcher. It must never contain real credentials.

🚫 **HARD RULE (SC-3):** OSF tokens and all credentials must be passed via environment variables or the gitignored secrets file. They must never be hardcoded in source files, configuration templates, or notebooks.

🚫 **HARD RULE (SC-4):** CI workflow files must not contain API keys, tokens, or model credentials. The `MOCK_LLM=true` environment variable must be set explicitly in the CI workflow to ensure no live model calls occur.

---

## 16. Audit Bundle Controls

🚫 **HARD RULE (AB-1):** The audit bundle (`audit_bundle_[run_id].zip`) must not be emitted until all of the following are validated:

| Condition | Error if False | Exit Code |
|---|---|---|
| All `evidence_review` files have non-null `human_verdict` | `ERR_VERDICT_INCOMPLETE` | 5 |
| `pass1_anchor_type` is NOT `"local"` | `ERR_ANCHOR_LOCAL_AT_BUNDLE` (see note) | 5 |
| Every artifact entry has a `strand` field | `ERR_STRAND_MISSING` | 5 |

⚠️ **GAP NOTE (AB-1):** `ERR_ANCHOR_LOCAL_AT_BUNDLE` is required by this rule but is not currently defined in `docs/error_codes.md` in the dev plan. The dev plan must be updated to add this code with exit code 5 and an action string directing the researcher to run `osf_uploader.py`. Until that update, implementors should treat this as a synthesis block equivalent to `ERR_VERDICT_INCOMPLETE`.

🚫 **HARD RULE (AB-2):** `audit_bundle_[run_id].json` metadata must include all of the following fields: `bundle_id`, `bundle_sha256`, `timestamp_utc`, `pre_registration_doi`, `pass1_hash`, `pass1_anchor_type`, `pass1_anchor_value`, `lens_hash`, `strand_labels`, `human_verdicts_complete`, `interpretive_propositions`, `hallucination_rate`, `theme_stability_score`, `jaccard_mean`, `lens_amplification_index`, `reviewer_ids`, `artifact_manifest`.

⚠️ **ADVISORY (AB-3):** If `pre_registration_doi` is null, the audit bundle should include a warning flag. This is an advisory — it does not block packaging — but examiners and supervisors will see the absence recorded in the bundle.

🚫 **HARD RULE (AB-4):** `bundle_sha256` must be computed over the complete `.zip` file after packaging. It must not be computed over the metadata JSON alone.

---

## 17. Testing and CI Controls

🚫 **HARD RULE (TC-1):** All 14 named tests defined in Phase 3 of the dev plan must be implemented. No partial test suite is acceptable at release.

🚫 **HARD RULE (TC-2):** All LLM calls in tests must be mocked using `unittest.mock.patch` with the `MOCK_LLM=true` environment flag. Tests must not require a live Ollama instance, network access, or any external service.

🚫 **HARD RULE (TC-3):** `make test-local` must run all 14 tests with no network access and no live model. `make test` (the CI target) must be equivalent.

🚫 **HARD RULE (TC-4):** CI workflow `.github/workflows/ci.yml` must set `MOCK_LLM: "true"` explicitly as an environment variable. No secrets may be stored in the CI workflow file.

🚫 **HARD RULE (TC-5):** The following tests are individually required and may not be consolidated or removed:

| Test | What It Enforces |
|---|---|
| `test_pass2_refuses_when_pass1_anchor_missing` | AR-6, PS gate |
| `test_pass2_refuses_when_pass1_anchor_is_local` | AR-6, PS gate |
| `test_pass2_refuses_when_lens_not_locked` | AR-2, HG-4 |
| `test_pass2_refuses_when_lens_signature_missing` | AR-2, HG-5 |
| `test_dpia_blocks_ingestion_for_special_category` | AR-3, DG-1 |
| `test_grounding_checker_flags_unsupported_claims` | grounding integrity |
| `test_grounding_checker_does_not_modify_claims` | HV-4 |
| `test_audit_emitter_includes_prereg_doi` | AB-2 |
| `test_audit_emitter_includes_pass1_hash` | AB-2 |
| `test_audit_emitter_includes_strand_labels` | SL-2 |
| `test_audit_emitter_blocks_if_verdicts_incomplete` | HV-3, AB-1 |
| `test_audit_emitter_blocks_if_anchor_local` | AR-6, AB-1 |
| `test_stability_report_contains_required_metrics` | PS-7 |
| `test_review_cli_rejects_anonymous_reviewer` | RI-1 |

---

## 18. Prompt Integrity Controls

🚫 **HARD RULE (PI-1):** The agent must read `docs/lens.md` before implementing `lens_dialogue.py`. All 10 questions must be extracted verbatim from that document. Inventing, paraphrasing, or summarising lens questions is prohibited.

🚫 **HARD RULE (PI-2):** The Pass 1 system prompt must be derived from `docs/workflow.md` Stage 1. It must not contain researcher lens, theoretical framing, or any hypothesis language. It must explicitly state the AI has been given no theoretical frame.

🚫 **HARD RULE (PI-3):** The Pass 2 system prompt must begin with the lens injection: `"You are now reading this data through the researcher's theoretical lens. The lens summary is as follows: {lens_summary}"`. The `{lens_summary}` placeholder must be filled from the locked lens JSON at runtime — never hardcoded or fabricated.

🚫 **HARD RULE (PI-4):** The Pass 2 system prompt must include a disconfirmation mandate and a lens-amplification guard warning. Omitting these is a methodological integrity failure.

🚫 **HARD RULE (PI-5):** `src/prompts/pass1_system_prompt.txt` and `src/prompts/pass2_system_prompt.txt` must exist as files in the repository. Prompt text must not be assembled inline in Python code from string constants.

---

## 19. Interpretive Proposition Controls

🚫 **HARD RULE (IP-1):** `interpretive_proposition: true` must be set automatically by `review_cli.py` when a claim is accepted with `support_strength: weak` or `support_strength: none`. The reviewer is notified at the point of acceptance.

🚫 **HARD RULE (IP-2):** The template sentence for interpretive propositions must be saved in the `evidence_review` JSON record:
> "[claim text], though this should be understood as an interpretive proposition rather than a data-grounded finding, supported by limited evidential basis ([support_strength]) and retained on the basis of [reviewer notes]."

🚫 **HARD RULE (IP-3):** The audit bundle `interpretive_propositions` field must list all `claim_id` values where `interpretive_proposition: true`. Supervisors and examiners use this list to verify methodological transparency.

⚠️ **ADVISORY (IP-4):** Claims accepted with `support_strength: strong` or `moderate` should not be flagged as interpretive propositions unless explicitly set by the reviewer. Auto-flagging strong evidence claims as interpretive propositions is an error.

---

## 20. Override Mechanisms

Unlike agentic development pipelines with configurable autonomy levels, this research pipeline has **no bypass or override mechanism** for its immutable hard blocks. The following controls have no documented override path:

| Control | Why no override exists |
|---|---|
| DPIA gate (DG-1, DG-2) | GDPR Article 9 and BPS ethics guidelines impose a legal/ethical obligation |
| Pass 2 anchor check (§4) | Tampering with the immutable anchor is a research integrity violation |
| Human verdict non-delegation (HV-1, HV-2) | AI-set verdicts would invalidate the methodological claim of human review |
| Local-only constraint (LO-1, LO-2) | DPIA constraint; not a preference |
| Researcher signature on lens (HG-5) | Unsigned lens means unattributed theoretical framing |

The only legitimate recovery path for any of these blocks is human action: completing the DPIA, depositing to OSF, completing the review CLI, providing an ORCID, or correcting configuration. The agent must surface the appropriate `Action:` string and wait.

---

## 21. Quick-Reference Table — All Hard Stops

### §A — Pass Sequencing Hard Stops

| ID | Trigger | Error Code | Exit | Recovery |
|---|---|---|---|---|
| PS-GATE-1 | `pass1_anchor_[id].json` absent at Pass 2 entry | `ERR_PASS1_ANCHOR_MISSING` | 3 | Run `pass1_runner.py` first |
| PS-GATE-2 | `pass1_hash` mismatch at Pass 2 entry | `ERR_PASS1_HASH_MISMATCH` | 3 | Restore `pass1_output` from OSF deposit or re-run Pass 1 on original data |
| PS-GATE-3 | `anchor_type == "local"` at Pass 2 entry | `ERR_PASS1_ANCHOR_LOCAL` | 3 | Run `osf_uploader.py`; update anchor with DOI or accession |
| PS-GATE-4 | Lens not locked (`locked != true`) | `ERR_LENS_NOT_LOCKED` | 4 | Complete lens dialogue; call `lock_lens()` |
| PS-GATE-5 | `researcher_signature` null | `ERR_LENS_SIGNATURE_MISSING` | 4 | Re-run `lock_lens()` with ORCID or institutional username |

### §B — DPIA and Governance Hard Stops

| ID | Trigger | Error Code | Exit | Recovery |
|---|---|---|---|---|
| DG-1 | `special_category` + `dpia_signed.json` absent (at ingest) | `ERR_DPIA_MISSING` | 2 | Complete DPIA checklist; obtain DPO sign-off; save to `artifacts/dpia_signed.json` |
| DG-2 | `special_category` + `dpia_signed.json` absent (at Pass 2) | `ERR_DPIA_MISSING` | 2 | As above |
| DG-3 | `dpia_signed.json` missing required fields | `ERR_DPIA_INVALID` | 2 | Ensure `dpo_name`, `signature_date`, `decision: approved` present |
| DG-4 | `sensitivity` value not recognised | `ERR_SENSITIVITY_UNKNOWN` | 1 | Set `sensitivity` in `config/defaults.yaml` to a valid value |

### §C — Audit and Synthesis Hard Stops

| ID | Trigger | Error Code | Exit | Recovery |
|---|---|---|---|---|
| AB-1 | Any `evidence_review` has `human_verdict: null` at emit time | `ERR_VERDICT_INCOMPLETE` | 5 | Run `review_cli.py` and complete all pending verdicts |
| AB-2 | `pass1_anchor_type == "local"` at emit time | (packaging blocked) | 5 | Deposit Pass 1 output to OSF; update anchor |
| AB-3 | Any artifact missing `strand` field at emit time | `ERR_STRAND_MISSING` | 5 | Add `strand` to artifact; re-run |
| RC-1 | `reviewer_id` null or anonymous in `review_cli.py` | (rejected at prompt) | — | Provide ORCID or institutional username |

### §D — Data Integrity Hard Stops

| ID | Trigger | Error Code | Exit | Recovery |
|---|---|---|---|---|
| PF-1 | Any of five pre-flight docs missing | `ERR_PREFLIGHT_MISSING` | 1 | Provide the missing document; convert HTML to Markdown if needed |
| AI-2 | `pass1_hash` does not match file SHA256 | `ERR_PASS1_HASH_MISMATCH` | 3 | Human recovery only — restore from OSF or re-run |
| SL-4 | `strand` missing from `pass2_output` claim | `ERR_STRAND_MISSING` | 5 | Revise Pass 2 prompt to include `strand` instruction; re-run |

### §E — All Hard Stops Quick Reference

| Symbol | ID | One-line description |
|---|---|---|
| 🛑 | PF-1 | Pre-flight document missing before Phase 0 |
| 🛑 | DG-1/2 | DPIA absent for special_category data |
| 🛑 | DG-3 | DPIA document missing required fields |
| 🛑 | PS-GATE-1 | Pass 1 anchor absent at Pass 2 entry |
| 🛑 | PS-GATE-2 | Pass 1 hash mismatch |
| 🛑 | PS-GATE-3 | Anchor type still local at Pass 2 entry |
| 🛑 | PS-GATE-4 | Lens not locked |
| 🛑 | PS-GATE-5 | Lens researcher signature absent |
| 🛑 | HV-3 | Evidence review verdicts incomplete at audit emit |
| 🛑 | AB-2 | Anchor type still local at audit emit |
| 🛑 | AB-3 | Strand field absent on any artifact at audit emit |
| 🛑 | AI-2 | Pass 1 hash mismatch (file integrity) |
| 🚫 | HV-1/2 | AI sets human_verdict to non-null (integrity violation) |
| 🚫 | LO-1/2 | External API used for participant data processing |
| 🚫 | SC-1 | Secrets committed to repository |
| 🚫 | AR-12 | Prompts invented rather than extracted from docs |
