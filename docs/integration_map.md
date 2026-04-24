"""Map of pipeline stages, artifacts, and human gates."""

# Integration Map

This table maps the full governed pipeline from ingest through release packaging. It shows which module owns each stage, what goes in, what comes out, which checks block progress, and where a human must decide.

| Stage | Module | Input artifact | Output artifact | Gate checks | Human decision points |
| --- | --- | --- | --- | --- | --- |
| 1. Governance onboarding | `config/defaults.yaml`, `artifacts/dpia_signed.json` | Study configuration and DPIA record | Approved local configuration state | Sensitivity set correctly; DPIA required for `special_category` studies | Researcher confirms study settings and DPO approval status |
| 2. Ingest + de-identify | `src/modules/ingest_and_deid.py` | Local raw transcript or session file | `artifacts/deidentified_[participant_code]_[session].json` plus raw local archive copy | Dataset ID path safety; DPIA hard gate; local-only processing | Researcher reviews de-identification quality |
| 3. Pass 1 blind analysis | `src/agent/pass1_runner.py` | De-identified dataset | `artifacts/pass1_output_[dataset_id].json`, `artifacts/pass1_anchor_[dataset_id].json` | Prompt loaded from disk; artifact written and hashed | Researcher reads blind-pass output without editing it |
| 4. Anchor deposit | `src/modules/osf_uploader.py` | Pass 1 output and local anchor | Updated `artifacts/pass1_anchor_[dataset_id].json` with external anchor value | Anchor cannot stay `local` before Pass 2 or audit packaging | Researcher uploads artifact to OSF or approved repository |
| 5. Lens dialogue | `src/modules/lens_dialogue.py` | Pass 1 observations and researcher reflexive input | `artifacts/lens_[run_id].json`, lens dialogue transcript | Lens must exist before lock; prompt from disk | Researcher answers questions and confirms summary |
| 6. Lens lock | `src/modules/lens_dialogue.py --lock` | Draft lens artifact | Locked `artifacts/lens_[run_id].json` with signature | `locked == true`; `researcher_signature` non-null | Researcher signs and locks the lens |
| 7. Pass 2 positioned analysis | `src/agent/pass2_runner.py` | Pass 1 anchor plus locked lens | `artifacts/pass2_output_[label]_[dataset_id].json` stability set | Anchor exists; hash matches; anchor type not local; lens exists; lens locked; signature present | Researcher reviews interpretive emphasis and disconfirming material |
| 8. Grounding verification | `src/modules/grounding_checker.py` | Pass 2 output | `artifacts/evidence_review_[claim_id]_[dataset_id].json` records | Claims must remain evidence-linked; verdicts start null | Researcher checks whether review records are understandable |
| 9. Human evidence review | `src/tools/review_cli.py` | Evidence review records | Completed evidence review records with `human_verdict` set | Only CLI may set `human_verdict`; reviewer ID validation | Reviewer accepts, revises, rejects, or rechecks claims |
| 10. Delta comparison | `src/prompts/pass1_vs_pass2_delta_prompt.txt` with local runner | Pass 1 output, Pass 2 output, locked lens summary | `artifacts/lens_delta_report_[dataset_id].md` | Inputs must be locked/committed artifacts; comparison stays local | Researcher checks what changed and why |
| 11. Audit emit + release handover | `src/modules/audit_emitter.py` and `src/modules/osf_uploader.py` | Anchored pass outputs, lens, evidence reviews, repo manifest | `artifacts/audit_bundle_[run_id].zip`, `artifacts/audit_bundle_[run_id].json`, external deposit record | No null verdicts; anchor externalised; strand fields present; raw archive excluded | Supervisor or researcher verifies bundle integrity and release readiness |

## Notes

- All AI processing remains local through Ollama-backed modules.
- External deposit is limited to governance anchors and audit bundles after the required gates pass.
- Human decisions are mandatory at lens lock and evidence verdict stages, with additional manual checks around deposit and handover.
