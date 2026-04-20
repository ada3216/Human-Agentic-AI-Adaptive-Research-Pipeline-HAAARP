#!/usr/bin/env python3
"""
apply_devplan_deltas.py
Applies the v2.2 delta insertions and replacements to Agentic_Pipeline_Dev_Plan_v2.1.md

Usage:
    python apply_devplan_deltas.py                        # auto-finds dev plan in same folder
    python apply_devplan_deltas.py --dry-run              # preview only, no writes
    python apply_devplan_deltas.py --file "/path/to/file" # explicit path

Output:
    - Backup: <filename>.bak
    - Patched file written in place
    - Per-delta pass/fail summary printed to stdout

Modes:
    insert_after  — inserts content immediately after the anchor string
    insert_before — inserts content immediately before the anchor string
    replace       — replaces the anchor string with content
"""

import argparse
import shutil
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import Literal


@dataclass
class Delta:
    id: str
    description: str
    mode: Literal["insert_after", "insert_before", "replace"]
    anchor: str
    content: str
    required: bool = True


DELTAS = [

    # ------------------------------------------------------------------
    # Delta 1a — Add guardrails reference as Task 1b in Phase 0
    # Anchor: Task 1's own line (line 60). insert_after places 1b
    # between Task 1 and Task 2.
    # ------------------------------------------------------------------
    Delta(
        id="1a",
        description="Phase 0: add Task 1b — read guardrails doc",
        mode="insert_after",
        anchor="1. Read `COPILOT_INSTRUCTIONS.md` if it exists. If it does not exist yet, create it now (see Task 8 below) before doing anything else.",
        content="\n\n1b. Read `guardrails-research-pipeline_v1.md` before writing any code or creating any files. This document is the enforcement specification for all absolute rules in this pipeline. It is a required read alongside `COPILOT_INSTRUCTIONS.md` — both must be read before any implementation begins.\n",
    ),

    # ------------------------------------------------------------------
    # Delta 1b — Developer notes: add rule 15
    # ------------------------------------------------------------------
    Delta(
        id="1b",
        description="Developer notes: add rule 15 — guardrails doc is enforcement authority",
        mode="insert_after",
        anchor="14. **Testing.** All 14 named tests must be implemented. MOCK_LLM=true. Tests pass with no network access and no live model.",
        content="\n\n15. **Guardrails document is the enforcement authority.** The rules in this section are summarised here for quick reference. The complete enforcement specification — including all HARD STOP definitions, human gate descriptions, recovery paths, and override restrictions — is in `guardrails-research-pipeline_v1.md`. In any conflict between a rule stated here and the guardrails document, the guardrails document takes precedence.\n",
    ),

    # ------------------------------------------------------------------
    # Delta 1c — Phase 3 Required inputs: add test plan reference
    # ------------------------------------------------------------------
    Delta(
        id="1c",
        description="Phase 3 Required inputs: add TEST_PLAN.md reference",
        mode="insert_after",
        anchor="- All Phase 2a and 2b modules implemented\n- `examples/dpia_signed.json` (Phase 0 example artifacts)\n- `examples/lens_example_locked.json` (Phase 0 example artifacts)",
        content="\n- `TEST_PLAN.md` v1.1 — the authority for test coverage decisions. If a behaviour is not described in the test plan, it is not considered tested.\n",
    ),

    # ------------------------------------------------------------------
    # Delta 1d — Phase 3 acceptance criteria: fix stale 14-test count
    # ------------------------------------------------------------------
    Delta(
        id="1d",
        description="Phase 3 acceptance: replace stale '14 tests' line with test plan reference",
        mode="replace",
        anchor="- `make test-local` runs all 14 tests with no network access and no live model",
        content='- `make test-local` runs all tests defined in `TEST_PLAN.md` (Layer 1 + Layer 2 + Layer 2b) with no network access and no live model. Note: `TEST_PLAN.md` v1.1 defines over 100 assertions across these layers — the "14 named tests" referenced in earlier phases are a subset. `TEST_PLAN.md` is the authority for coverage completeness.',
    ),

    # ------------------------------------------------------------------
    # Delta 1e — Master acceptance checklist: replace single test line
    # ------------------------------------------------------------------
    Delta(
        id="1e",
        description="Master acceptance checklist: replace single test line with 4-layer criteria",
        mode="replace",
        anchor="- [ ] All 14 pytest tests pass with MOCK_LLM=true",
        content='- [ ] All test layers in `TEST_PLAN.md` pass at the minimum bar defined in its "Minimum passing bar" section\n- [ ] `make test-local` exits 0 with no live model and no network (covers TEST_PLAN Layers 1, 2, 2b)\n- [ ] Layer 3 end-to-end produces valid `audit_bundle_DEMO.zip` with `pass1_anchor_type: osf_doi`\n- [ ] Layer 4 adversarial tests all produce correct error and exit code (`pytest tests/test_adversarial.py -v`)',
    ),

    # ------------------------------------------------------------------
    # Delta 2a — error_codes.md: add ERR_ANCHOR_LOCAL_AT_BUNDLE
    # Inserts after ERR_PASS1_ANCHOR_LOCAL in Pass sequencing section
    # ------------------------------------------------------------------
    Delta(
        id="2a",
        description="error_codes.md: add ERR_ANCHOR_LOCAL_AT_BUNDLE after ERR_PASS1_ANCHOR_LOCAL",
        mode="insert_after",
        anchor='ERR_PASS1_ANCHOR_LOCAL    \u2014 anchor_type is "local"; external deposit required before Pass 2\n  Action: Deposit pass1_output to OSF or institutional repo. Run osf_uploader.py, then\n          update artifacts/pass1_anchor_[dataset_id].json with anchor_type and anchor_value.',
        content='\n\nERR_ANCHOR_LOCAL_AT_BUNDLE \u2014 anchor_type is still "local" at audit bundle emit time\n  Action: Deposit pass1_output to OSF. Run osf_uploader.py to upgrade anchor_type to\n          osf_doi or repo_accession before emitting the audit bundle.\n  Exit code: 5\n',
    ),

    # ------------------------------------------------------------------
    # Delta 2b — error_codes.md: add ERR_PASS2_RUN_MISSING
    # insert_before ERR_LENS_NOT_LOCKED keeps it in the Pass sequencing
    # section (exit code 3 errors), not in Data/schema errors.
    # ------------------------------------------------------------------
    Delta(
        id="2b",
        description="error_codes.md: add ERR_PASS2_RUN_MISSING in Pass sequencing section",
        mode="insert_before",
        anchor="ERR_LENS_NOT_LOCKED       \u2014 lens_[run_id].json exists but locked != true",
        content='ERR_PASS2_RUN_MISSING     \u2014 one or more of the four required Pass 2 output files is absent\n  Action: Re-run pass2_runner.py. Identify which run (seed42, seed99, seed123, deterministic)\n          is missing from artifacts/ and determine whether the run failed silently.\n  Exit code: 3\n\n',
    ),

    # ------------------------------------------------------------------
    # Delta 2c — error_codes.md: add filesystem/dataset error section
    # ------------------------------------------------------------------
    Delta(
        id="2c",
        description="error_codes.md: add filesystem/dataset error section after Preflight",
        mode="insert_after",
        anchor="ERR_PREFLIGHT_MISSING     \u2014 required pre-flight document not found\n  Action: See docs listed in Pre-flight section of the dev plan.\n          Convert HTML to Markdown if needed: pandoc file.html -o file.md",
        content='\n\n## Filesystem and dataset errors\nERR_DATASET_INVALID       \u2014 dataset_id contains illegal characters (path traversal, null bytes, slashes)\n  Action: Provide a dataset_id containing only alphanumeric characters, hyphens, and\n          underscores. Do not use path separators or special characters.\n  Exit code: 1\n\nERR_DATASET_COLLISION     \u2014 dataset_id already exists in artifacts/ and --force not set\n  Action: Use a unique dataset_id, or pass --force to overwrite the existing run.\n          Warning: overwriting will destroy the existing pass1_anchor and output.\n  Exit code: 1\n',
    ),

    # ------------------------------------------------------------------
    # Delta 2d — error_codes.md: update return codes table
    # ------------------------------------------------------------------
    Delta(
        id="2d-code3",
        description="error_codes.md: update exit code 3 to include ERR_PASS2_RUN_MISSING",
        mode="replace",
        anchor="  3   \u2014 ERR_PASS1_ANCHOR_MISSING, ERR_PASS1_HASH_MISMATCH, or ERR_PASS1_ANCHOR_LOCAL",
        content="  3   \u2014 ERR_PASS1_ANCHOR_MISSING, ERR_PASS1_HASH_MISMATCH, ERR_PASS1_ANCHOR_LOCAL,\n          or ERR_PASS2_RUN_MISSING",
    ),

    Delta(
        id="2d-code5",
        description="error_codes.md: update exit code 5 to include ERR_ANCHOR_LOCAL_AT_BUNDLE",
        mode="replace",
        anchor="  5   \u2014 ERR_VERDICT_INCOMPLETE or ERR_STRAND_MISSING (synthesis block)",
        content="  5   \u2014 ERR_VERDICT_INCOMPLETE, ERR_STRAND_MISSING, or ERR_ANCHOR_LOCAL_AT_BUNDLE\n        (synthesis block)",
    ),

    # ------------------------------------------------------------------
    # Delta 3a — Phase 2a: add schema files to acceptance criteria
    # Appends bullet points to the existing list. No extra --- or header.
    # ------------------------------------------------------------------
    Delta(
        id="3a",
        description="Phase 2a acceptance criteria: add schema file requirements",
        mode="insert_after",
        anchor="- `lock_lens()` records `researcher_role` in lens JSON",
        content="\n- `src/schemas/anchor_schema.json` present and validates `pass1_anchor_[dataset_id].json` (fields: `pass1_hash` 64-char hex, `anchor_type` enum, `strand` enum, `timestamp_utc` ISO-8601, `operator_id` non-null)\n- `src/schemas/lens_schema.json` present and validates `lens_[run_id].json` (fields: `locked` boolean, `researcher_signature` non-null when locked, `lens_summary_hash` 64-char hex when locked)\n- `src/schemas/dpia_schema.json` present and validates `artifacts/dpia_signed.json` (fields: `dpo_name` non-null, `signature_date` ISO-8601, `decision: \"approved\"`, `dpia_complete: true`, `sensitivity_class` non-null)\n",
    ),

    # ------------------------------------------------------------------
    # Delta 3b — Phase 2b: add stability schema task
    # insert_before Task 3 (line 553) which is outside the code fence.
    # Previous version anchored inside ```python block — now fixed.
    # ------------------------------------------------------------------
    Delta(
        id="3b",
        description="Phase 2b: add stability_schema.json task before Task 3",
        mode="insert_before",
        anchor="3. Create `src/prompts/pass2_system_prompt.txt`. **Agent must READ `docs/lens.md` and `docs/workflow.md` before writing.**",
        content="2a. Create `src/schemas/stability_schema.json` \u2014 validates `stability_report_[dataset_id].json`. Required fields: `theme_stability_score` (number 0.0\u20131.0), `jaccard_mean` (number), `jaccard_pairs` (array), `lens_amplification_index` (number), `unstable_themes` (array). Values may be `null` for mocked runs but keys must be present. `compute_stability_metrics()` output must validate against this schema before being written to disk.\n\n",
    ),

    # ------------------------------------------------------------------
    # Delta 4 — Phase 3: add test tasks 2a–2d
    # ------------------------------------------------------------------
    Delta(
        id="4",
        description="Phase 3: add Tasks 2a-2d — security, filesystem, ingest, prompt tests",
        mode="insert_after",
        anchor="That is 14 named tests. Mock all LLM calls using `unittest.mock.patch` with `MOCK_LLM=true` env flag.",
        content="\n\n**Task 2a \u2014 `tests/test_security.py`**\n- T-SEC-01: parse `requirements.txt` and assert none of the banned packages are present: `openai`, `anthropic`, `langchain`, `llamaindex`, `cohere`, `replicate`, `huggingface_hub`, `assemblyai`, `deepgram`, `boto3`, `google-cloud-storage`\n- T-SEC-02: walk `src/` Python files using `ast.parse` and assert no `import` or `from`-import of banned packages appears in any source file\n\n**Task 2b \u2014 `tests/test_filesystem.py`**\n- T-FS-01: `dataset_id` containing `../` is rejected with `ERR_DATASET_INVALID` before any file is written\n- T-FS-02: `dataset_id` containing `/`, `\\\\`, or null bytes is rejected\n- T-FS-03: pipeline refuses to overwrite an existing `pass1_output_[dataset_id].json` without `--force` flag\n- T-FS-04: duplicate `dataset_id` in same run triggers `ERR_DATASET_COLLISION`\n- T-FS-05: all artifact writes go to `artifacts/` \u2014 no file written outside repo root\n\n**Task 2c \u2014 `tests/test_ingest.py`**\n- T-INGEST-01: `deidentify()` produces output files named `deidentified_[code]_[session].json` only\n- T-INGEST-02: `participant_code_map` is never written to any file that analysis modules accept as input\n- T-INGEST-03: `spot_check_prompt()` blocks execution until researcher types `confirmed` (mock stdin)\n- T-INGEST-04: analysis modules reject input files that do not match the `deidentified_*.json` naming pattern\n\n**Task 2d \u2014 `tests/test_prompts.py`**\n- T-PROMPT-01: `src/prompts/pass1_system_prompt.txt` contains the required no-framing statement: `\"You have not been given any theoretical frame\"`\n- T-PROMPT-02: `src/prompts/pass2_system_prompt.txt` contains the disconfirmation mandate\n- T-PROMPT-03: `src/prompts/pass2_system_prompt.txt` contains the lens injection placeholder `{lens_summary}`\n- T-PROMPT-04: `lens_dialogue.LENS_QUESTIONS` contains exactly 10 non-empty strings\n",
    ),

    # ------------------------------------------------------------------
    # Delta 5 — config/defaults.yaml: fix misleading provider comment
    # ------------------------------------------------------------------
    Delta(
        id="5",
        description="config/defaults.yaml: clarify local-only as hard constraint",
        mode="replace",
        anchor="  provider: local                    # local | (hosted only if not special_category data)",
        content="  provider: local                    # HARD CONSTRAINT: must always be local.\n                                     # The local-only rule is enforced by DPIA and applies\n                                     # regardless of sensitivity level. Any other value causes\n                                     # the pipeline to halt at startup. See guardrails LO-5.",
    ),

]


# ---------------------------------------------------------------------------
# Engine
# ---------------------------------------------------------------------------

def apply_deltas(text: str, dry_run: bool = False):
    results = []
    for delta in DELTAS:
        if delta.anchor not in text:
            results.append({"id": delta.id, "status": "FAIL \u2014 anchor not found", "description": delta.description})
            print(f"  [FAIL] Delta {delta.id}: anchor not found.")
            print(f"         {delta.description}")
            print(f"         Anchor (first 80 chars): {delta.anchor[:80]!r}")
            continue

        if delta.mode == "insert_after":
            replacement = delta.anchor + delta.content
        elif delta.mode == "insert_before":
            replacement = delta.content + delta.anchor
        elif delta.mode == "replace":
            replacement = delta.content
        else:
            raise ValueError(f"Unknown mode: {delta.mode}")

        if not dry_run:
            text = text.replace(delta.anchor, replacement, 1)

        results.append({"id": delta.id, "status": "DRY-RUN OK" if dry_run else "OK", "description": delta.description})

    return text, results


def main():
    parser = argparse.ArgumentParser(description="Apply v2.2 deltas to the dev plan.")
    parser.add_argument("--file", help="Path to dev plan .md file (auto-detected if omitted)")
    parser.add_argument("--dry-run", action="store_true", help="Preview only, no writes")
    args = parser.parse_args()

    if args.file:
        target = Path(args.file)
    else:
        candidates = list(Path(".").glob("Agentic_Pipeline_Dev_Plan*.md"))
        if not candidates:
            print("ERROR: No dev plan file found in current directory.")
            print("       Use --file <path> or run from the same folder as the file.")
            sys.exit(1)
        if len(candidates) > 1:
            print(f"ERROR: Multiple matches: {[str(c) for c in candidates]}")
            print("       Use --file <path> to specify which one.")
            sys.exit(1)
        target = candidates[0]

    if not target.exists():
        print(f"ERROR: File not found: {target}")
        sys.exit(1)

    print(f"\n{'DRY RUN \u2014 ' if args.dry_run else ''}Applying deltas to: {target}\n")

    backup = target.with_suffix(target.suffix + ".bak")
    if not args.dry_run:
        shutil.copy2(target, backup)
        print(f"Backup: {backup}\n")

    original = target.read_text(encoding="utf-8")
    patched, results = apply_deltas(original, dry_run=args.dry_run)

    passed = [r for r in results if "OK" in r["status"]]
    failed = [r for r in results if "FAIL" in r["status"]]

    print("\nResults:")
    print("-" * 65)
    for r in results:
        icon = "\u2713" if "OK" in r["status"] else "\u2717"
        print(f"  {icon} [{r['id']:>10}]  {r['status']:<22}  {r['description']}")
    print("-" * 65)
    print(f"  Passed: {len(passed)}/{len(results)}    Failed: {len(failed)}/{len(results)}\n")

    if failed and not args.dry_run:
        print(f"WARNING: {len(failed)} delta(s) not applied. Apply manually.")
        print(f"         Original preserved at: {backup}\n")

    if not args.dry_run:
        target.write_text(patched, encoding="utf-8")
        print(f"Written: {target}")

    sys.exit(2 if failed else 0)


if __name__ == "__main__":
    main()
