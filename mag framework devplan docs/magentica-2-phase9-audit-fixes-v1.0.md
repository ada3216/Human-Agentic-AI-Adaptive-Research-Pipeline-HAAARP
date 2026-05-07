# Phase 9 — Audit Fixes

**Version:** 1.0 | **Date:** 2026-04-23
**Scope:** CONTAINED
**Risk:** MEDIUM (touches frozen agent files — see exception below)

**Files touched:**
- `.opencode/agents/mag.md`
- `.opencode/agents/reviewer.md`
- `.opencode/agents/executor.md`
- `.opencode/commands/implement.md`
- `.opencode/commands/prime.md`
- `.opencode/commands/review.md`
- `scripts/phase-complete.sh`
- `scripts/session-start.sh`
- `docs/README.md`
- `tests/canary/phase-9.sh`

**Goal:** Close the workflow correctness gaps identified in the post-build audit. Eliminates
all dead-end states, aligns UX messaging, and hardens peripheral scripts. Divided into two
sections by urgency — Part A must ship before real-repo use; Part B is polish that can
wait until after a few repo runs if preferred.

**Prerequisites:** `bash tests/canary/phase-8.sh` exits 0.

⚠️ **INV-AGENT-1 EXCEPTION:** `mag.md`, `reviewer.md`, and `executor.md` are normally
frozen. This phase has an explicit exception for surgical fixes only. No behavioural
changes, no new instructions, no structural changes — only the specific line edits
listed below. Any deviation requires a new plan cycle.

---

## Part A — Critical (do before first real-repo run)

These fix dead-end states and hard UX blocks. None are optional.

---

### Fix 1 — REVIEW_FAIL clears pending_review (S0-02)

**Problem:** `reviewer.md` sets `pending_review=true` on REVIEW_FAIL and never clears it.
`implement.md` blocks on `pending_review=true`. Result: one REVIEW_FAIL locks the user
out of `/implement` permanently until manual state edit.

**Note:** Three consecutive REVIEW_FAILs already auto-clear via the escalation path
(`reviewer.md:115-119`). The gap is the single-fail case.

**Fix — `reviewer.md`:**
On the REVIEW_FAIL path, add after the existing REVIEW_FAIL emit:
```
bash scripts/state.sh set pending_review false
```
The REVIEW_PASS path already clears it — this makes FAIL symmetric.

**Fix — `implement.md:7`:**
Remove the independent `pending_review` check entirely. `mag.md:23` is the sole
enforcement point for routing. Duplicating the check in `implement.md` creates a
secondary block that persists even after `reviewer.md` clears the flag if the session
hasn't reloaded state.

---

### Fix 2 — REVIEW_STOP template updated (S0-01 + Gap 1 + Gap 2)

**Problem:** `mag.md` lines 44–56 REVIEW_STOP template has three issues:
1. "Open a new session with a DIFFERENT AI provider" — mandatory, no override path.
2. No mention of `/commit` as resolution when tree is dirty.
3. REVIEW_FAIL path says "run /implement again" — which is blocked.

**Fix — `mag.md` REVIEW_STOP format (lines 44–56):**
Replace the Next steps block with:

```
Next steps:
1. If uncommitted changes remain: run /commit first
2. Switch to a DIFFERENT AI provider (strong default — log attestation if not possible)
3. In that new session, run: /review
4. REVIEW OUTCOME: PASS — return here and run /plan for the next phase
5. REVIEW OUTCOME: FAIL — return here and run /implement again
```

---

### Fix 3 — Remove destructive git restore (S0-03)

**Problem:** Two locations silently discard uncommitted work:
- `.opencode/commands/prime.md:5` — runs `git restore` on protected files
- `scripts/phase-complete.sh:17` — runs `git restore` before phase transition

Both are silent and destructive. No user warning, no opt-out.

**Fix:** Delete both `git restore` lines. If protected-file integrity is needed,
replace with a read-only diff/warn — never a silent restore.

**Canary update:** `tests/canary/phase-5.sh:50` currently asserts `git restore` is
present in `prime.md`. Update this assertion to confirm `git restore` is **absent**.

---

### Fix 4 — executor.md pending_review block allows /commit (Gap 3 extension)

**Problem:** `executor.md:22` globally blocks on `pending_review=true`. This includes
`/commit`. If the tree is dirty during a pending review, the user cannot commit — but
the resolution path (Fix 2 above) requires running `/commit` first.

**Fix — `executor.md`:**
Narrow the pending_review block to exclude the commit command path. The simplest
implementation: add a check before the block — if the active command is `commit`,
skip the pending_review gate entirely.

---

## Part B — Polish (can defer until after first real-repo runs)

These are correctness improvements but will not cause hard blocks in normal usage.

---

### Fix 5 — Scope file-size check to governed source files (S1-04)

**Problem:** `reviewer.md:50` checks "any file over max_file_lines" with no extension
qualification. `USERGUIDE.md` at 730 lines would trigger this. Narrative docs should
never fail a source-size gate.

**Fix — `reviewer.md`:**
Qualify the file-size check to governed source extensions only (the same set defined
by `governed_languages` in `PROJECT_CONFIG.md`). Docs, markdown, and config files
should emit an advisory at most.

---

### Fix 6 — session-start WARN not FAIL when lint-check.sh absent (S2-07)

**Problem:** `scripts/session-start.sh:18` hard-FAILs if `scripts/lint-check.sh` is
missing. This file is gitignored and generated by `/project-init`. A developer who
hasn't run `/project-init` yet gets a blocking error on session start rather than a
helpful hint.

**Fix — `scripts/session-start.sh`:**
Downgrade to WARN with message:
```
WARN: scripts/lint-check.sh not found. Run /project-init to generate it.
Session start continuing.
```
Do not exit non-zero.

---

### Fix 7 — REVIEW_ATTEST log schema adds task + slot (S2-09)

**Problem:** `review.md:24` logs `switched | reason | policy` but omits `task` and
`slot`. REVIEW_ATTEST entries cannot be correlated with REVIEW_PASS/REVIEW_FAIL
entries for the same task.

**Fix — `review.md`:**
Update the REVIEW_ATTEST log format to:
```
REVIEW_ATTEST | task: <current_task> | slot: <implement_slot> | switched: <yes/no> | reason: <reason> | policy: <policy>
```
Read `current_task` and `implement_slot` from `state.json` via `state.sh` at log time.

---

### Fix 8 — README two-provider hard requirement softened (Gap 4)

**Problem:** `README.md` lines 433–434 list "Access to at least two AI providers" as a
hard requirement. Single-provider mode with attestation override is now supported.

**Fix — `README.md`:**
Change to:
```
Two AI providers strongly recommended. Single-provider override supported via
attestation (log reason when not switching).
```

---

### Fix 9 — CI lint alignment (Task B from follow-up scope plan)

**Problem:** `.github/workflows/ci.yml` runs `flake8 src/ tests/` while the project
has migrated to Ruff via `scripts/lint-check.sh`. CI and local diverge silently.

**Fix:**
1. Replace the CI lint step with `bash scripts/lint-check.sh`
2. Remove `flake8` from any requirements/dev-dependencies
3. Verify `make lint` calls `bash scripts/lint-check.sh`

---

### Fix 10 — Function-length violations resolved (Task A from follow-up scope plan)

**Problem:** Two functions exceed `max_function_lines: 50`:
- `implementation docs/apply_devplan_deltas.py` — `main()`
- `src/modules/ollama_client.py` — `call_generate()`

**Fix (choose per function):**
- Refactor: extract sub-functions as described in the follow-up scope plan
- Or: add `# EXEMPT: cohesive atomic unit` per the exemption policy if refactoring
  would reduce clarity

Resolve whichever way makes the code better — the point is to clear the violation.

---

## Acceptance Criteria

All Part A criteria are BLOCKING. Part B criteria are BLOCKING only if Part B is
included in this implementation cycle.

1. `reviewer.md` REVIEW_FAIL path calls `bash scripts/state.sh set pending_review false`
2. `implement.md` does not contain an independent `pending_review` check
3. `mag.md` REVIEW_STOP Next steps block contains `/commit` as step 1
4. `mag.md` REVIEW_STOP Next steps block contains "strong default" for provider switch
5. `mag.md` REVIEW_STOP FAIL path says "run /implement again" (not blocked after Fix 1)
6. `prime.md` does not contain `git restore`
7. `scripts/phase-complete.sh` does not contain `git restore`
8. `tests/canary/phase-5.sh` asserts `git restore` is ABSENT from `prime.md`
9. `executor.md` pending_review gate does not block the commit command path
10. *(Part B)* `reviewer.md` file-size check is scoped to governed source extensions
11. *(Part B)* `scripts/session-start.sh` emits WARN (not FAIL) when lint-check.sh absent
12. *(Part B)* `review.md` REVIEW_ATTEST format includes `task:` and `slot:` fields
13. *(Part B)* `README.md` two-provider requirement uses "strongly recommended" language
14. *(Part B)* CI lint step runs `bash scripts/lint-check.sh` not flake8
15. *(Part B)* Both function-length violations resolved (refactored or exempted)
16. Phase 8 canary still exits 0

---

## Canary: `tests/canary/phase-9.sh`

Use the same `check()` pattern as all prior canaries.

Part A checks:
1. `reviewer.md` contains `set pending_review false` on a line following REVIEW_FAIL
2. `implement.md` does not contain `pending_review` as a check condition
3. `mag.md` REVIEW_STOP block contains the token `run /commit first`
4. `mag.md` REVIEW_STOP block contains `strong default`
5. `prime.md` does not contain `git restore`
6. `scripts/phase-complete.sh` does not contain `git restore`
7. `tests/canary/phase-5.sh` does NOT assert git restore present in prime.md
8. `executor.md` commit path is not blocked by pending_review gate

Part B checks (add if Part B implemented):
9. `scripts/session-start.sh` contains `WARN` near lint-check.sh reference
10. `review.md` REVIEW_ATTEST line contains `task:` and `slot:`
11. `README.md` contains `strongly recommended` near two-provider reference

---

## Implementation note

Run Part A as one plan/implement/review cycle.
Run Part B as a separate cycle after at least one real-repo run, unless there is a
specific reason to ship it sooner. Part B fixes are all low-blast-radius and the
real-repo run will confirm whether any of them are causing active friction.
