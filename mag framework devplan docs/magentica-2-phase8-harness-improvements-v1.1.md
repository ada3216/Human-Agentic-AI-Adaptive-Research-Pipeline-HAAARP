# Phase 8 — Harness Improvements

**Version:** 1.1 | **Date:** 2026-04-23
**Scope:** CONTAINED
**Risk:** LOW

**Inspired by:** Ryan Lopopolo, "Harness Engineering" (OpenAI, Feb 2026); Birgitta Böckeler, "Harness engineering for coding agent users" (martinfowler.com, Apr 2026)

**Files touched:**
- `scripts/lint-adapters/js-ts.sh`
- `scripts/lint-adapters/python.sh`
- `scripts/lint-adapters/shell.sh`
- `scripts/lint-adapters/README.md`
- `scripts/check.sh`
- `.opencode/commands/cold-review.md`
- `.opencode/commands/slop-gc.md`
- `.opencode/skills/workflow/SKILL.md`
- `tests/canary/phase-8.sh`

**Goal:** Five targeted improvements to the harness derived from harness engineering principles:
1. Lint adapters emit structured `LINT-REMEDIATION` blocks — feedback sensors optimised for LLM consumption, providing just-in-time remediation context to the executor via Gate 1 without requiring agent file changes.
2. `/cold-review` accepts an optional persona lens argument to focus the review on a specific engineering concern.
3. `check.sh` gains a `Structure` section that hard-fails on file size violations, with full respect for the Phase 7 intelligent exemption system already in `PROJECT_CONFIG.md`.
4. New `/slop-gc` command that sequences the existing Magentica tools into a garbage-collection workflow for eliminating recurring failure patterns.
5. `workflow/SKILL.md` updated to document the `LINT-REMEDIATION` format, the persona convention, the `/slop-gc` command, and a note on continuous drift sensors as an unimplemented harness pattern.

**Prerequisites:** `bash tests/canary/phase-7.sh` exits 0.

🚫 **HARD RULE:** `executor.md`, `reviewer.md`, `planner.md`, and `mag.md` are frozen (INV-AGENT-1). None are modified in this phase. The just-in-time context benefit (improvement 1) is delivered through the lint adapter output itself — the executor receives structured remediation text via Gate 1, without any change to agent files.

🚫 **HARD RULE:** The Phase 7 exemption system (`max_file_lines_exempt_globs`, `max_file_lines_overrides`, `max_function_lines_exemption_policy` in `PROJECT_CONFIG.md`) must be read and respected by every enforcement change in this phase. Do not add a second exemption mechanism. Extend the existing one.

---

## Background

Two complementary sources ground this phase.

**Ryan Lopopolo (OpenAI)** identified four principles transferable to Magentica:
- Lint failures should prompt, not just report — provide remediation guidance at the point of failure.
- Structural checks should be hard gates, not advisories — the architectural spec should be executable.
- Review agents should have a persona — focus review energy by engineering concern.
- Slop elimination should be a scheduled loop — convert observed recurring failures into durable lint rules.

**Birgitta Böckeler (martinfowler.com)** formalised the underlying taxonomy:
- **Guides (feedforward controls)** — steer the agent *before* it acts, increasing the probability of a correct first attempt.
- **Sensors (feedback controls)** — observe *after* the agent acts and help it self-correct. "Particularly powerful when they produce signals optimised for LLM consumption, e.g. custom linter messages that include instructions for the self-correction — a positive kind of prompt injection."
- **Computational sensors** — deterministic, fast, run on every change: linters, structural tests, type checkers.
- **Inferential sensors** — semantic, run by a model: review agents, AI judges.

Magentica's existing gates (Gate 1, Gate 2) are computational sensors. The reviewer agent is an inferential sensor. Phase 8's `LINT-REMEDIATION` block upgrades the computational sensors to also be optimised for LLM consumption — making them function as both sensors and just-in-time feedforward guides simultaneously. The Fowler framing is why this matters: a lint failure that pastes raw tool output is a sensor; a lint failure that also tells the executor *what to do next* is a sensor that doubles as a guide.

Böckeler also identifies **continuous drift sensors** — checks that run continuously against the codebase *outside* the change lifecycle (dead code detection, coverage quality, dependency drift). These are not implemented in this phase but are documented in `workflow/SKILL.md` as a known harness pattern for future consideration.

---

## Component 1: Structured `LINT-REMEDIATION` blocks in lint adapters

**What to change in each of the three lint adapters:**

Each adapter already runs its lint tool and exits non-zero on failure. The addition is: when the lint tool exits non-zero, prepend a structured header block to the output before the raw lint tool output. This block is what the executor sees first via Gate 1 — it functions as a just-in-time feedforward guide, not just a sensor signal.

The block format to emit (to stdout, before the raw tool output) when the adapter fails:

```
LINT-REMEDIATION: [adapter-name]
Rule context:     [one line — what class of rule fired, read from the rule file name or tool output]
Fix guidance:     [one line — the most common remediation for this adapter's rules]
Rule docs:        .ai-layer/lint-rules/tier-1/ — read the matching .rules.md for the stated intention
Exempt paths:     Check PROJECT_CONFIG.md max_file_lines_exempt_globs before splitting files
```

**For `js-ts.sh`:** The rule context line should reflect whether the violation is a size rule (max-lines, max-lines-per-function) or a project-specific rule (read from the `.eslint.json` filenames in tier-1). Fix guidance for size rules: "Split the file or function — or verify the path is exempt in PROJECT_CONFIG.md before splitting." Fix guidance for project-specific rules: "Read the matching .rules.md file in .ai-layer/lint-rules/tier-1/ for the intent behind this rule."

**For `python.sh`:** Rule context: "Ruff rule violation — see rule code in output below." Fix guidance: "Run `ruff check --fix` for auto-fixable rules. For EM1xx (exception message) rules, move the string to a variable before raising."

**For `shell.sh`:** Rule context: "ShellCheck warning." Fix guidance: "ShellCheck output includes the SC code and a direct fix suggestion. Address each SC code in the output."

**Implementation approach for each adapter:** The adapter currently calls the lint tool and exits with its exit code. Restructure so that: (a) the lint tool output is captured to a variable or temp file, (b) if the exit code is non-zero, emit the `LINT-REMEDIATION` block first, then emit the captured output, then exit non-zero. If the exit code is zero, emit nothing extra and exit zero. Do not alter the lint tool invocation itself — only wrap the output.

**For `js-ts.sh` specifically:** The rule context line should try to extract the most common rule name from the ESLint output (the string after the rule name in parentheses in ESLint's output format) and surface it. If extraction is not straightforward, fall back to "ESLint rule violation — see rule name in output below." Do not add complexity that could break the adapter.

**Update `scripts/lint-adapters/README.md`:** Add to the "Interface every adapter must satisfy" section a fifth requirement: "On failure: emit a LINT-REMEDIATION block before the raw tool output (see workflow/SKILL.md for the exact format and field names). This makes the sensor signal optimised for LLM consumption — the executor reads the structured guidance first, then the raw output."

---

## Component 2: Persona lens on `/cold-review`

**What to change in `.opencode/commands/cold-review.md`:**

The current command body begins with "Review the provided file path or diff WITHOUT any session implementation context." Keep this opening. Add the following immediately after it, before the "Read .ai-layer/ARCHITECTURE.md" line:

Add a persona argument section:

If the human invokes the command with a persona flag (examples: `--as reliability`, `--as security`, `--as scalability`, `--as frontend`, `--as readability`), apply a focused lens on that dimension before running the four standard dimensions. The focused lens means: weight findings in that dimension more heavily, spend more review attention on it, and flag lower-severity issues in that dimension that would otherwise be ADVISORY as WEAK.

The five supported personas and their focus areas:
- `reliability` — timeouts, retries, error handling, graceful degradation, circuit breakers
- `security` — credential handling, injection vectors, input validation, output encoding, access control
- `scalability` — unbounded loops, N+1 queries, missing pagination, synchronous blocking in hot paths
- `frontend` — component decomposition, state management, snapshot testability, prop drilling, accessibility
- `readability` — naming, function length, cognitive complexity, inline comments on non-obvious logic

If no persona flag is provided, all four dimensions are weighted equally (existing behaviour — do not change).

After the focused lens section, proceed with the four standard rating dimensions as currently written. Do not remove or reorder them.

At the end of the OVERALL line, if a persona was specified, append: `(reviewed with [persona] lens)`

No new files. No changes to reviewer.md (INV-AGENT-1).

---

## Component 3: Hard-fail structure check in `check.sh`

**What to change in `scripts/check.sh`:**

Add a new section called `Structure` after the existing `Lint` section and before the `Secrets` section. This placement is deliberate: lint-level issues are already visible above, reducing duplicate noise, and structure violations are caught before they reach the secrets scan or tests. This follows the "keep quality left" principle — find issues as early in the check sequence as possible.

The section must do the following, in order:

**Step 1 — Read configuration from `PROJECT_CONFIG.md`.** Extract these four values using grep/awk or a small inline python3 snippet:
- `max_file_lines` — the hard limit (default 300 if not set)
- `max_file_lines_overrides` — a YAML mapping of `path: limit` pairs (may be absent)
- `max_file_lines_exempt_globs` — a list of glob patterns that are fully exempt (may be absent)
- `max_function_lines_exemption_policy` — if present and non-empty, cohesive atomic unit exemptions apply to function length

**Step 2 — Build the exempt glob list.** If `max_file_lines_exempt_globs` is present, extract each pattern. These paths are skipped entirely during the structure check.

**Step 3 — Find files over the limit.** Use `find` to locate all tracked source files (exclude `node_modules`, `.git`, `__pycache__`). For each file:
- Check if the file's path matches any exempt glob — if yes, skip.
- Check if the file has a per-file override in `max_file_lines_overrides` — if yes, use that limit instead of `max_file_lines`.
- Count lines. If over the applicable limit, record as a violation.

**Step 4 — Report violations.** For each violation, output one line in this format:
```
STRUCTURE FAIL: [filepath] — [actual line count] lines (limit: [applicable limit])
  Exempt paths: check max_file_lines_exempt_globs in PROJECT_CONFIG.md
  Per-file overrides: check max_file_lines_overrides in PROJECT_CONFIG.md
```
Increment the `FAIL` counter for each violation.

**Step 5 — Function length.** The function length check is already covered by Gate 1 lint advisory (js-ts and python adapters both enforce `max_function_lines`). The `check.sh` structure section should not duplicate this. Instead, add one note line at the end of the section: `NOTE: function length enforcement is via Gate 1 lint advisory — see lint section above.` If `max_function_lines_exemption_policy` is present and non-empty, add: `NOTE: function length exemption policy active — cohesive atomic units exempt per PROJECT_CONFIG.md.`

**Step 6 — If no violations:** Output `structure: all files within limits ([N] files checked, [M] exempt)`.

**Key constraint:** The Structure section must import no new shell dependencies. It must use only `find`, `wc`, `grep`, `awk`, and optionally a small inline `python3` snippet for reading the YAML-like config from `PROJECT_CONFIG.md`. The python snippet approach is consistent with how `state.sh` and other scripts in this repo already handle config reads.

---

## Component 4: `/slop-gc` command

**Create `.opencode/commands/slop-gc.md`:**

The frontmatter:
```yaml
---
name: slop-gc
agent: executor
---
```

The command body (no code blocks — instruction prose only):

The slop-gc command is a garbage-collection pass that converts observed recurring failure patterns into durable lint rules — closing the steering loop described by Fowler: "Whenever an issue happens multiple times, the feedforward and feedback controls should be improved to make the issue less probable in the future." Run it periodically — after a cluster of REVIEW_FAILs on the same type of issue, or at the end of a development sprint.

Sequence of steps the executor must follow:

**Step 1 — Mine decisions.md for recurring patterns.** Read `.ai-layer/decisions.md` in full. Find all `REVIEW_FAIL` entries. Group them by the type of issue described — by the *category* of problem, not by task name (e.g. "file too large", "missing error handling", "hardcoded credential", "function too long"). Any issue category that appears in three or more distinct `REVIEW_FAIL` entries across different tasks is a slop pattern.

**Step 2 — Report slop patterns found.** Output a numbered list of slop patterns identified, with the count of occurrences for each. If no patterns meet the three-occurrence threshold, output "No recurring patterns found — no lint rules needed." and stop.

**Step 3 — For each slop pattern, produce a structured diagnosis.** For each pattern: output the same structured diagnosis that `/fix-report` would produce — ROOT CAUSE, AFFECTED, LIKELY FIX, CONFIRM BEFORE FIXING, RISK — but applied to the *class* of failure rather than a specific instance.

**Step 4 — Propose a lint rule for each pattern.** For each slop pattern, propose one lint rule addition that would prevent it automatically. The proposal must include:
- Which lint adapter would enforce it (`js-ts`, `python`, `shell`, or a new structural check in `check.sh`)
- What rule file name to create in `.ai-layer/lint-rules/tier-1/`
- What the `.rules.md` explanation should say (one sentence: the intent, not the mechanism)
- That the rule must include a `LINT-REMEDIATION` message when the adapter emits failure output (all rules added via this command must satisfy the Component 1 interface)

**Step 5 — Confirm before acting.** Surface the full proposal to the human. Do not write any files until the human confirms. The confirmation prompt is: "Confirm [N] lint rules above? (yes / select / skip)"
- `yes` — proceed with all rules
- `select [numbers]` — proceed with only the listed rule numbers
- `skip` — stop, no files written

**Step 6 — On confirmation, route to `/plan`.** Do not implement rules directly. The lint rule additions are a governed change — they go through the standard plan/implement/review cycle. Produce `.ai-layer/current-plan.md` describing: which rule files to create, which adapters to update, and which `.rules.md` files to write. Set scope to CONTAINED, risk to LOW.

**Step 7 — Append to decisions.md:**
`DATE: [today] | PLAIN_SUMMARY | slop-gc | Identified [N] recurring patterns, proposed [M] lint rules, [K] confirmed for implementation.`

---

## Component 5: `workflow/SKILL.md` updates

**What to add to `.opencode/skills/workflow/SKILL.md`:**

**Addition 1 — LINT-REMEDIATION format.** Add a new section after the `retry-budget.sh calling convention` section:

```markdown
## LINT-REMEDIATION block format

When a lint adapter fails, it emits a structured block before the raw lint output:

LINT-REMEDIATION: [adapter-name]
Rule context:     [what class of rule fired]
Fix guidance:     [most common remediation]
Rule docs:        .ai-layer/lint-rules/tier-1/ — read the matching .rules.md
Exempt paths:     Check PROJECT_CONFIG.md max_file_lines_exempt_globs before splitting files

The executor reads this block first via Gate 1. The raw lint output follows.
This format makes the computational sensor signal optimised for LLM consumption —
it functions as a just-in-time feedforward guide as well as a feedback sensor.

Do not split or rename a file based on a size violation before checking whether its
path is covered by max_file_lines_exempt_globs or max_file_lines_overrides in PROJECT_CONFIG.md.

All lint adapters must emit this block on failure. See lint-adapters/README.md for the interface.
```

**Addition 2 — `/cold-review` persona convention.** Find the `/cold-review` row in the full command list table. Update its Purpose column entry to: `Rate any file/diff on architecture, security, readability, sensitive data. Optional: --as [persona] for focused lens (reliability, security, scalability, frontend, readability)`.

**Addition 3 — `/slop-gc` command.** Add a new row to the full command list table:

| `/slop-gc` | executor | Mine decisions.md for recurring REVIEW_FAIL patterns; produce structured diagnosis; propose and confirm lint rules; route confirmed rules to /plan |

**Addition 4 — Continuous drift sensors note.** Add a section after the LINT-REMEDIATION section:

```markdown
## Continuous drift sensors (not yet implemented)

The Fowler harness taxonomy identifies a third category of sensor beyond the change lifecycle:
sensors that run continuously against the codebase regardless of recent commits. Examples:
dead code detection, test coverage quality, dependency vulnerability drift, architectural decay.

Magentica's current sensors are all change-lifecycle sensors (Gate 1 after write, Gate 2 at commit,
reviewer at phase completion). Continuous drift sensors would require a scheduled runner outside
the normal workflow. This is a known gap — not a defect — and is noted here for future phases.
```

**Addition 5 — SLOP_GC type in decisions table.** The `/slop-gc` command appends a `PLAIN_SUMMARY` entry, which is the correct type for a non-technical summary of a completed action. No new type is needed. Do not add `SLOP_GC` to the type table.

---

## Phase 8 Guardrail Notes

- The `LINT-REMEDIATION` output format is a convention established in this phase. All three adapters must emit it consistently. The `lint-adapters/README.md` interface spec is updated in this phase to require it — any future adapter added after Phase 8 must include it.
- The `check.sh` Structure section reads `PROJECT_CONFIG.md` directly. It does not call `state.sh` (which is for `state.json` only). This is correct.
- The Structure section must never fail on exempt paths. The Phase 7 exemption policy exists precisely so that the check can be strict everywhere else. A false positive on an exempt path is a worse outcome than missing a real violation.
- `/slop-gc` does not implement lint rules directly — it produces a plan. This preserves the plan/implement/review cycle for all architectural changes. The command body must not contain any direct file write instructions for `lint-rules/tier-1/`. It mentions that path only in the context of what the *plan* will contain.
- `cold-review.md` is a command file, not an agent file. It may be modified in this phase without the INV-AGENT-1 exception path.
- After this phase, `workflow/SKILL.md` contains 15 commands in the command list (13 base + `/freeze-audit` from sensitive profile + `/slop-gc` from this phase). Verify the count before closing.
- The author name is Ryan Lopopolo (not Leapo). The devplan should use the correct name in this section header if it references the source.

## Phase 8 Acceptance Criteria

All criteria are BLOCKING.

1. All three lint adapters emit a `LINT-REMEDIATION` block (containing the token `LINT-REMEDIATION:`) to stdout when they fail, before the raw tool output.
2. Each `LINT-REMEDIATION` block contains `Rule context:`, `Fix guidance:`, `Rule docs:`, and `Exempt paths:` fields.
3. `scripts/lint-adapters/README.md` contains the token `LINT-REMEDIATION` in the interface spec section.
4. `check.sh` contains a `Structure` section header (matching the `── [Name] ──` format used by existing sections).
5. The Structure section references `max_file_lines_exempt_globs`.
6. The Structure section references `max_file_lines_overrides`.
7. The Structure section reads `max_file_lines` from `PROJECT_CONFIG.md` (verify by grepping for `PROJECT_CONFIG.md` within the Structure section of check.sh).
8. A file matching any pattern in `max_file_lines_exempt_globs` does not produce a `STRUCTURE FAIL` — the section skips it.
9. A file matching a `max_file_lines_overrides` entry is checked against its override limit, not the default.
10. `.opencode/commands/cold-review.md` contains `--as` and lists all five persona names: `reliability`, `security`, `scalability`, `frontend`, `readability`.
11. `.opencode/commands/slop-gc.md` exists and contains references to `decisions.md` and `REVIEW_FAIL`.
12. `slop-gc.md` routes confirmed rules to `/plan` — verify by presence of `current-plan.md` or the token `/plan` in the command body.
13. `slop-gc.md` does not contain direct file write instructions for `lint-rules/tier-1/` as an action step — it only mentions that path in the context of what the plan will contain (the proposal step).
14. `workflow/SKILL.md` contains `LINT-REMEDIATION`, `slop-gc`, and the continuous drift sensors note.
15. `workflow/SKILL.md` command list contains 15 entries (verify count).
16. Phase 7 canary still exits 0.

---

## Canary: `tests/canary/phase-8.sh`

The canary verifies structural presence and key tokens. It does not run lint tools (those require project-specific setup). Write the canary using the same `check() { if eval "$2" 2>/dev/null; then echo "PASS $1"; PASS=$((PASS+1)); else echo "FAIL $1"; FAIL=$((FAIL+1)); fi; }` pattern used in all prior canaries.

Checks to implement:

1. `js-ts.sh` contains the token `LINT-REMEDIATION`
2. `python.sh` contains the token `LINT-REMEDIATION`
3. `shell.sh` contains the token `LINT-REMEDIATION`
4. `js-ts.sh` contains `Rule context:` (spot-check that the block fields are present in at least one adapter; the pattern is the same across all three)
5. `js-ts.sh` contains `Exempt paths:`
6. `lint-adapters/README.md` contains `LINT-REMEDIATION`
7. `check.sh` contains the Structure section header — grep for `Structure` inside a section header pattern matching the existing `── Name ──` format used by other sections
8. `check.sh` references `max_file_lines_exempt_globs`
9. `check.sh` references `max_file_lines_overrides`
10. `check.sh` references `PROJECT_CONFIG.md` within the structure check logic
11. `.opencode/commands/cold-review.md` contains `--as`
12. `.opencode/commands/cold-review.md` contains `reliability`
13. `.opencode/commands/cold-review.md` contains `scalability` (second spot-check)
14. `.opencode/commands/slop-gc.md` exists
15. `slop-gc.md` contains `REVIEW_FAIL`
16. `slop-gc.md` contains `current-plan.md` or `/plan` (routes to plan, not direct write)
17. `workflow/SKILL.md` contains `LINT-REMEDIATION`
18. `workflow/SKILL.md` contains `slop-gc`
19. `workflow/SKILL.md` contains `continuous drift` (the unimplemented sensors note)
20. Phase 7 regression: `bash tests/canary/phase-7.sh`

The final lines must use the `PASS=$PASS FAIL=$FAIL` / `[ "$FAIL" -eq 0 ]` pattern. The phase-7 regression check should suppress stdout and only surface failure details: `bash tests/canary/phase-7.sh > /dev/null 2>&1` for the eval, with the failing canary name in the FAIL message.

---

## What Was NOT Changed and Why

| Considered | Decision | Reason |
|---|---|---|
| `executor.md` — add JIT context re-read instruction | Not changed | INV-AGENT-1 (agent freeze). JIT context is delivered through the `LINT-REMEDIATION` block in adapter output — same benefit via the computational sensor, no agent file change required. |
| `reviewer.md` — add persona-aware review | Not changed | INV-AGENT-1. Persona support is at the command layer (`cold-review.md`), which is the correct boundary. |
| `check.sh` function length hard-fail | Not added | `max_function_lines_exemption_policy` makes it impossible to safely hard-fail without project-specific knowledge about cohesive units. Gate 1 lint advisory is the right enforcement path for function length. File length hard-fail IS added (Component 3). |
| Continuous drift sensors (dead code, coverage quality) | Documented but not implemented | Requires a scheduled runner outside the change lifecycle — different scope from Phase 8. Noted in `workflow/SKILL.md` for future phases. |
| New lint adapter for a fourth language | Not in scope | New adapters follow the updated `lint-adapters/README.md` interface (which now requires `LINT-REMEDIATION`). Adding one is a `/project-init` concern, not a framework phase. |
| `/architecture-fitness` command | Not in scope | The Fowler taxonomy identifies architecture fitness functions as a harness category. Magentica's `ARCHITECTURE.md` + reviewer adversarial checks cover this, but a dedicated fitness function sensor is a Phase 9 candidate. |
