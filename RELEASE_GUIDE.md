"""Release procedure for governed publication artifacts."""

# Release Guide

This guide covers the Phase 4 release path for a governed local-only pipeline build.

## 1. GitHub release tagging

1. Confirm working tree is clean.
2. Run `bash scripts/check.sh`.
3. Create an annotated tag for the release version.
4. Push the tag to the remote repository.
5. Draft the GitHub release notes summarising governance-relevant changes.

## 2. OSF project creation and deposit

1. Create or open the OSF project used for governance deposits.
2. Prepare `osf_deposit_example/osf_metadata_example.json` as the metadata reference.
3. Upload the release audit materials and any approved governance anchors.
4. Record the returned OSF URL or DOI.
5. If the deposit updates a Pass 1 anchor, run `python src/modules/osf_uploader.py --anchor <anchor-path> --doi <osf-url>`.

## 3. DOI minting

1. Confirm the OSF project or institutional repository is configured to mint a DOI.
2. Review contributor names, title, description, and license metadata before minting.
3. Mint the DOI only after the release artifact set is final.
4. Record the DOI in the release notes and audit metadata.

## 4. audit bundle upload

1. Generate the bundle locally with `python src/modules/audit_emitter.py --dataset-id <dataset-id> --run-id <run-id>`.
2. Confirm the ZIP excludes `artifacts/raw_archive/` material.
3. Upload the ZIP and matching metadata JSON to the approved repository.
4. Record the repository URL in project documentation.

## 5. post-release verification

1. Re-download the uploaded audit bundle.
2. Compare its SHA256 with the local value recorded by `audit_emitter.py`.
3. Confirm the GitHub tag, OSF record, and DOI landing page all point to the same release version.
4. Verify no credentials, participant identifiers, or raw archive files are present in published artifacts.

## Reference modules

- `src/modules/osf_uploader.py` records governed external deposit details.
- `src/modules/audit_emitter.py` creates the audit bundle and bundle hash used for verification.
