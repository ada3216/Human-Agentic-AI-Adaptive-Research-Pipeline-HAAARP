# Phase 8.1 — Micro Brief: `/doc-garden` and `/slop-gc` Golden Principles Mod

**Version:** 1.1 | **Date:** 2026-04-23
**Scope:** CONTAINED | **Risk:** LOW | **Files touched:** 3

---

## Change 1: `/doc-garden` command

**Create `.opencode/commands/doc-garden.md`**

Frontmatter:
```yaml
---
name: doc-garden
agent: executor
---
```

Command body (instruction prose only — no code blocks):

The doc-garden command scans the repository for documentation that has drifted out of sync with the actual code and proposes targeted fix-up pull requests. It is the documentation equivalent of `/slop-gc`: where slop-gc targets lint-detectable code patterns, doc-garden targets stale or incorrect prose that misleads future agent runs.

Run it on a regular cadence — weekly, or after any significant refactor — because documentation that does not reflect real code behaviour is worse than no documentation: it actively misdirects the executor.

Steps the executor must follow:

**Step 1 — Identify doc/code pairs to check.** The scan targets are:
- `docs/` — all markdown files
- `.ai-layer/ARCHITECTURE.md` — the primary architectural record
- `.ai-layer/PROJECT_CONFIG.md` — project constraints and config keys

Do NOT scan `.opencode/` (commands, agents, and skills are instruction surfaces, not factual documentation). Do NOT scan `.ai-layer/decisions.md`, `.ai-layer/state.json`, `.ai-layer/current-plan.md`, or `.ai-layer/integrity-baseline.txt` — these are operational files, not documentation.

Within the scan targets, identify files that make factual claims about specific code behaviour — e.g. files that name specific modules, function signatures, file paths, config keys, or describe data flows. Skip files that are purely structural (index pages, table of contents, link lists).

**Step 2 — For each doc/code pair, check for drift.** For each factual claim in the documentation, locate the code it describes. Drift categories to look for:
- Named file or module no longer exists at the stated path
- Named function, class, or export no longer exists or has been renamed
- Described behaviour contradicts what the code actually does (e.g. a claimed default value, a stated config key, a described data flow)
- Documented architectural constraint is no longer enforced (check against active lint rules in `.ai-layer/lint-rules/tier-1/`)

**Step 3 — Produce a drift report.** For each drift found, output one entry:
```
DOC-DRIFT: [doc file path]:[line number]
Claim:    [the specific factual claim in the doc]
Reality:  [what the code actually shows]
Fix:      [one-line description of the correction needed]
Severity: [STALE — outdated but harmless | MISLEADING — actively wrong | BROKEN — named path/module does not exist]
```
If no drift is found, output "No documentation drift detected." and stop.

**Step 4 — Confirm before acting.** Show the full report to the human. Do not modify any files. The confirmation prompt is: "Fix [N] drift items above? (yes / select / skip)"
- `yes` — proceed with all fixes
- `select [numbers]` — proceed with only the listed items
- `skip` — stop, no files written

**Step 5 — On confirmation, apply fixes directly.** Doc fixes do not go through a plan cycle — they are corrections to documentation only, not architectural or lint-rule changes, and do not require the plan/implement/review governed cycle. Apply each confirmed fix as a direct edit. Keep each fix minimal: correct only the specific claim that has drifted, do not rewrite surrounding prose.

**Step 6 — Append to decisions.md:**
`DATE: [today] | PLAIN_SUMMARY | doc-garden | Scanned [N] doc/code pairs, found [M] drift items, fixed [K].`

---

## Change 2: `/slop-gc` — add golden principles framing

**Modify `.opencode/commands/slop-gc.md`**

Make two targeted additions to the existing command body:

**Addition A — Opening framing.** After the first sentence ("The slop-gc command is a garbage-collection pass..."), insert:

The lint rules produced by this command are *golden principles*: opinionated, mechanical rules that keep the codebase legible and consistent for future agent runs. A golden principle is not a stylistic preference — it is a rule that, once encoded, applies everywhere at once and compounds over time. The goal is to capture human taste once and enforce it continuously, rather than catching the same class of error repeatedly in review.

**Addition B — Step 4 `.rules.md` instruction update.** Find the existing line "What the `.rules.md` explanation should say (one sentence: the intent, not the mechanism)" and extend it to:

What the `.rules.md` explanation should say (one sentence: the intent, not the mechanism). Frame it as a golden principle — state what the rule protects, not how it works. Example: "Async helpers must use the shared bounded-concurrency utility so invariants are centralised and observable." Not: "Use mapWithConcurrency instead of Promise.all."

---

## workflow/SKILL.md addition

Add a new row to the command list table:

| `/doc-garden` | executor | Scan docs/ and .ai-layer/ architecture files for drift against actual code; confirm and apply targeted corrections |

Update the command count in the Phase 8 guardrail notes from 15 to 16.

---

## Acceptance criteria

1. `.opencode/commands/doc-garden.md` exists.
2. `doc-garden.md` contains `DOC-DRIFT` (the drift report format token).
3. `doc-garden.md` contains `MISLEADING` and `BROKEN` (severity levels).
4. `doc-garden.md` does NOT mention `.opencode/` as a scan target.
5. `doc-garden.md` explicitly excludes `decisions.md` from scanning.
6. `doc-garden.md` applies fixes directly — confirmed by absence of the phrase "Produce .ai-layer/current-plan.md" and the phrase "route to /plan" in the command body.
7. `doc-garden.md` appends to `decisions.md` on completion.
8. `slop-gc.md` contains `golden principle` or `golden principles`.
9. `slop-gc.md` `.rules.md` instruction contains example framing (spot-check for `centralised` or `observable`).

## Canary additions for `tests/canary/phase-8.sh`

Add these checks to the existing phase-8 canary (checks 21–25):

21. `doc-garden.md` exists
22. `doc-garden.md` contains `DOC-DRIFT`
23. `doc-garden.md` contains `BROKEN`
24. `doc-garden.md` does NOT contain the phrase `Produce .ai-layer/current-plan.md` — use: `! grep -q "Produce .ai-layer/current-plan.md" .opencode/commands/doc-garden.md`
25. `slop-gc.md` contains `golden`

Update the final command count assertion in the phase-8 canary (if present) from 15 to 16.
