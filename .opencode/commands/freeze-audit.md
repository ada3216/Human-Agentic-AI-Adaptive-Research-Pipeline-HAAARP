---
name: freeze-audit
agent: reviewer
---
Produce a freeze-time assurance record for this project. This command is run once
before tagging a study deployment build. It is not part of the normal
plan/implement/review cycle.

Steps:
1. Perform brownfield audit checks inline (do not call /brownfield-audit as a slash
   command — perform the checks directly):
   - File size violations: find files over max_file_lines; list with counts
   - Sensitive data risks: scan for credential patterns, PII in committed files
   - Infrastructure status: check state.json, decisions.md, lint-check.sh, gatekeeper.js
   - Language coverage: languages in codebase vs adapters in scripts/lint-adapters/
   Produce the standard BLOCKERS / RECOMMENDATIONS / ALREADY COMPLIANT / NEXT STEP format.

2. Perform cold review inline on each file listed in ARCHITECTURE.md ## Data flow that
   handles sensitive data (ask human to confirm the file list before reviewing). For each:
   - ARCHITECTURE FIT: [STRONG | ACCEPTABLE | WEAK | FAIL]
   - SECURITY POSTURE: [STRONG | ACCEPTABLE | WEAK | FAIL]
   - READABILITY: [STRONG | ACCEPTABLE | WEAK | FAIL]
   - SENSITIVE DATA: [CLEAN | ADVISORY | FAIL]

3. Read the last 20 decisions.md entries. Summarise:
   (For the PLAIN LANGUAGE SUMMARY section below, run a separate full-file grep:
   grep 'PLAIN_SUMMARY' .ai-layer/decisions.md | tail -5
   Do not rely on the tail-20 window for PLAIN_SUMMARY entries — on mature projects
   they will not appear there.)
   - How many plan/implement/review cycles completed
   - How many REVIEW_FAILs occurred and whether they were resolved
   - Any ESCALATION entries and their resolution
   - Any DESIGN_STOP decisions affecting data handling
4. Read current state.json and confirm: phase=idle, pending_review=false,
   design_stop_pending=false. If any are not in their clean state: flag and stop.
5. Produce FREEZE AUDIT RECORD in this exact format:

FREEZE AUDIT RECORD
Date: [ISO date]
Project: [project_name from PROJECT_CONFIG.md]
data_sensitivity: [value]
Build commit: [git rev-parse HEAD]

GOVERNANCE SUMMARY
Completed cycles: [N plan/implement/review cycles from decisions.md]
Review failures: [N, resolved Y/N]
Escalations: [N, resolved Y/N]
Design decisions affecting data handling: [list or "none"]

BROWNFIELD STATUS
[paste BLOCKERS section from brownfield-audit output]
[paste RECOMMENDATIONS section]

DATA HANDLING FILES REVIEWED
[for each file from cold-review: filename, ARCHITECTURE FIT rating, SENSITIVE DATA rating]

STATE AT FREEZE
phase: idle ✓  pending_review: false ✓  design_stop_pending: false ✓

PROVIDERS USED
Implement slot active at freeze: [implement_slot from state.json]
Note: model rotation was [active (informed-yolo) | inactive (full-yolo)] during this build.
      (For sensitive projects, full-yolo is blocked by Part 2 — this will always read informed-yolo
      on a correctly configured sensitive project.)

PLAIN LANGUAGE SUMMARY
[Find all PLAIN_SUMMARY entries in decisions.md (grep '| PLAIN_SUMMARY |' .ai-layer/decisions.md).
 Paste the last 5 verbatim. If fewer than 5 exist, paste all available — do not pad or
 synthesise entries. These are non-technical descriptions of what was built, written by
 the AI reviewer at implementation time on a different provider from the implementor.]

FREEZE AUDIT COMPLETE
To tag this build: git tag -a "freeze-[date]" -m "Ethics board submission build"

6. Append to decisions.md: DATE: [today] | FREEZE_AUDIT | commit: [hash] | cycles: [N] | sensitivity: [value]
