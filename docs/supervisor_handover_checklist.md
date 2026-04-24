# Supervisor Handover Checklist

Purpose: verify that the governed artifact bundle, config fields, and review records are complete before supervisor sign-off.

## Checklist

- [ ] Pre-registration DOI is present and deposited before data collection. Reference: config study registration field and deposited record metadata.
- [ ] Pass 1 hash matches the recorded anchor, and `anchor_type` is `osf_doi` or `repo_accession` rather than `local`. Reference: `artifacts/pass1_anchor_*.json`.
- [ ] Lens JSON is locked and includes `researcher_signature` with ORCID. Reference: `artifacts/lens_*.json`.
- [ ] Stability report documents theme stability score and Jaccard mean. Reference: `artifacts/pass2_output_*.json` or linked stability artifact.
- [ ] All `human_verdict` fields are complete with no null values. Reference: `artifacts/evidence_review_*.json` and review export records.
- [ ] Hallucination rate is documented. Reference: audit bundle summary and supporting review metrics.
- [ ] All interpretive propositions are explicitly labelled with the required template sentence. Reference: final report outputs and governed analysis artifacts.
- [ ] Krippendorff's α with confidence interval is reported for PDA coding, if the PDA strand is active. Reference: strand-specific results artifact.
- [ ] Member checking response records are present, if the IPA strand is active. Reference: participant response record artifact or linked appendix.
- [ ] DPIA signed record is present in the artifact bundle. Reference: `artifacts/dpia_signed.json` and `artifacts/dpia_checklist.md`.
- [ ] Reviewer IDs use ORCID or institutional username only; no anonymous verdicts. Reference: reviewer records in `artifacts/evidence_review_*.json`.

## Artifact and config references

- `artifacts/pass1_anchor_*.json`
- `artifacts/lens_*.json`
- `artifacts/evidence_review_*.json`
- `artifacts/dpia_signed.json`
- `artifacts/dpia_checklist.md`
- `config/defaults.yaml` and study-specific config files

## Supervisor sign-off

- **Supervisor Name:** ______________________________
- **Supervisor Role:** ______________________________
- **Supervisor Signature:** _________________________
- **Date:** YYYY-MM-DD
- **Outcome:** [ ] Approved for handover  [ ] Revision required
- **Notes:** _______________________________________
