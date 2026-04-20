---
name: review
agent: reviewer
---
IMPORTANT: This command is intended to run on a DIFFERENT AI provider from the one
that ran /implement. If you are the same provider that implemented, surface this
warning clearly before proceeding.

Preflight checks (run in order):
  1. bash scripts/state.sh get pending_review
     If false: report that no review is pending and stop.
  2. Read `.ai-layer/PROJECT_CONFIG.md` and resolve rotation policy fields:
     - `rotation_policy: [recommended|strict]` (default to `recommended` if missing)
     - `single_provider_mode: [true|false]` (default to `false` if missing)
     - `review_attestation: [required|optional]` (default to `required` if missing)
  3. Collect review attestation before invoking reviewer:
     - `switched_provider: yes|no`
     - If `no`, capture `reason` (required)
     - If `rotation_policy=strict` and `switched_provider=no`:
       allow proceed only when either `single_provider_mode=true` or a non-empty
       explicit reason is provided in this session.
     - Never hard-block into a dead-end loop when pending_review=true.
     - Append to decisions.md before reviewer invocation:
       `DATE: [today] | REVIEW_ATTEST | switched: [yes|no] | reason: [text or none] | policy: [rotation_policy]`
  4. git status --porcelain
     If output is non-empty: surface REVIEW BLOCKED (uncommitted changes — see
     reviewer.md step 2 for the full block). Stop. Do not invoke the reviewer.
     /implement now commits as part of implement_complete; uncommitted changes
     mean implementation did not complete cleanly.

If both preflight checks pass: invoke the reviewer.
On REVIEW OUTCOME: PASS the reviewer sets pending_review=false.
On REVIEW OUTCOME: FAIL pending_review stays true — human returns to original provider.
