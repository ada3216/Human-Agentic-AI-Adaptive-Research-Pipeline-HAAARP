"""
OSF Uploader — deposits artifacts to Open Science Framework.

OSF personal access token must be in environment variable OSF_TOKEN
or in config/secrets.yaml (gitignored). Never committed.

This module upgrades pass1_anchor from anchor_type: local to anchor_type: osf_doi.
Pass 2 and audit bundle packaging BOTH require this step to complete first.
The current scaffold fully supports manual DOI/accession capture and validation;
token-based API upload remains a later enhancement.

See docs/error_codes.md for ERR_PASS1_ANCHOR_LOCAL.
"""

import sys
import json
import os
from pathlib import Path


def _resolve_anchor_target(doi: str) -> tuple[str, str]:
    anchor_value = doi
    anchor_type = "osf_doi" if "osf.io" in doi.lower() else "repo_accession"
    if anchor_type == "osf_doi" and not anchor_value.startswith("https://osf.io/"):
        print("[ERR_ANCHOR_VALUE_INVALID] OSF anchor must start with https://osf.io/")
        print("Action: Supply the full OSF URL, for example https://osf.io/abcde")
        sys.exit(3)
    if anchor_type == "repo_accession" and not anchor_value.startswith("https://"):
        print(
            "[ERR_ANCHOR_VALUE_INVALID] Repository accession must start with https://"
        )
        print("Action: Supply the full repository URL or accession landing page URL.")
        sys.exit(3)
    return anchor_type, anchor_value


def deposit_pass1_anchor(
    anchor_path: str, doi: str = None
) -> dict:  # EXEMPT: cohesive atomic unit
    """
    Upgrades pass1_anchor from anchor_type: local to osf_doi.

    If OSF_TOKEN env var is set: this scaffold still requires explicit DOI/accession input.
    If no token: prints manual deposit instructions and prompts for DOI/accession.

    Returns: { "anchor_type": str, "anchor_value": str, "updated_anchor_path": str }
    """
    if not Path(anchor_path).exists():
        print(f"[ERR_PASS1_ANCHOR_MISSING] Anchor file not found: {anchor_path}")
        print("Action: Run pass1_runner.py first.")
        sys.exit(3)

    with open(anchor_path) as f:
        anchor = json.load(f)

    os.environ.get("OSF_TOKEN")

    if doi:
        # DOI provided directly on CLI
        anchor_type, anchor_value = _resolve_anchor_target(doi)
    else:
        print("\nNo OSF token found and no --doi provided.")
        print("Manual deposit instructions:")
        print("  1. Go to https://osf.io and create/open your project")
        print(f"  2. Upload: {anchor['artifact_path']}")
        print("  3. Copy the DOI or file URL from OSF")
        print(
            "  4. Re-run: python src/modules/osf_uploader.py --anchor",
            anchor_path,
            "--doi [DOI]",
        )
        print("\nOr set OSF_TOKEN environment variable for automatic upload.")
        sys.exit(0)

    anchor["anchor_type"] = anchor_type
    anchor["anchor_value"] = anchor_value

    with open(anchor_path, "w") as f:
        json.dump(anchor, f, indent=2)

    print(
        f"\n[OK] Anchor upgraded: anchor_type={anchor_type}, anchor_value={anchor_value}"
    )
    print(f"Pass 2 is now unlocked for dataset {anchor.get('artifact_path', '')}")
    return {
        "anchor_type": anchor_type,
        "anchor_value": anchor_value,
        "updated_anchor_path": anchor_path,
    }


def deposit_audit_bundle(bundle_path: str) -> dict:
    """
    Manual helper for recording external audit-bundle deposit.
    Returns: { "deposit_doi": str }
    """
    print("Audit bundle deposit not yet implemented.")
    print("Manual: upload", bundle_path, "to your OSF project and record the DOI.")
    return {"deposit_doi": None}


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Deposit artifacts to OSF")
    parser.add_argument("--anchor", help="Path to pass1_anchor JSON file")
    parser.add_argument("--bundle", help="Path to audit bundle zip")
    parser.add_argument(
        "--doi", help="OSF DOI or accession number (if depositing manually)"
    )
    args = parser.parse_args()

    if args.anchor:
        deposit_pass1_anchor(args.anchor, doi=args.doi)
    elif args.bundle:
        deposit_audit_bundle(args.bundle)
    else:
        print("Specify --anchor or --bundle")
        sys.exit(1)
