**Applies to:** Artifact-producing Python modules in `src/agent/` and `src/modules/`.
**Rule:** Preserve deterministic artifact filename patterns (`pass1_output_*`, `pass1_anchor_*`, `pass2_output_*`, `evidence_review_*`, `audit_bundle_*`) so auditors can grep and trace lifecycle outputs.
**Example:** `artifacts/pass2_output_seed42_[dataset_id].json` and `artifacts/evidence_review_[claim_id]_[dataset_id].json`.
**Rationale:** Supports ARCHITECTURE.md artifact conventions and review traceability.
