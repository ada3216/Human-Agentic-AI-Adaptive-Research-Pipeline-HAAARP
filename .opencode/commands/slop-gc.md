---
name: slop-gc
agent: executor
---
The slop-gc command is a garbage-collection pass that converts observed recurring failure patterns into durable lint rules - closing the steering loop described by Fowler: whenever an issue happens multiple times, the feedforward and feedback controls should be improved to make the issue less probable in the future. Run it periodically after a cluster of REVIEW_FAILs on the same type of issue, or at the end of a development sprint.

Sequence of steps the executor must follow:

Step 1 - Mine decisions.md for recurring patterns. Read `.ai-layer/decisions.md` in full. Find all `REVIEW_FAIL` entries. Group them by the category of issue described, not by task name. Any issue category that appears in three or more distinct `REVIEW_FAIL` entries across different tasks is a slop pattern.

Step 2 - Report slop patterns found. Output a numbered list of slop patterns identified, with the count of occurrences for each. If no patterns meet the three-occurrence threshold, output `No recurring patterns found - no lint rules needed.` and stop.

Step 3 - For each slop pattern, produce a structured diagnosis. For each pattern, output the same structured diagnosis that `/fix-report` would produce - ROOT CAUSE, AFFECTED, LIKELY FIX, CONFIRM BEFORE FIXING, RISK - but applied to the class of failure rather than a specific instance.

Step 4 - Propose a lint rule for each pattern. For each slop pattern, propose one lint rule addition that would prevent it automatically. The proposal must include which lint adapter would enforce it (`js-ts`, `python`, `shell`, or a new structural check in `check.sh`), what rule file name to create in `.ai-layer/lint-rules/tier-1/`, what the `.rules.md` explanation should say in one sentence, and that the rule must include a `LINT-REMEDIATION` message when the adapter emits failure output.

Step 5 - Confirm before acting. Surface the full proposal to the human. Do not write any files until the human confirms. The confirmation prompt is: `Confirm [N] lint rules above? (yes / select / skip)`.
- `yes` - proceed with all rules
- `select [numbers]` - proceed with only the listed rule numbers
- `skip` - stop, no files written

Step 6 - On confirmation, route to `/plan`. Do not implement rules directly. The lint rule additions are a governed change and must go through the standard plan/implement/review cycle. Produce `.ai-layer/current-plan.md` describing which rule files to create, which adapters to update, and which `.rules.md` files to write. Set scope to CONTAINED and risk to LOW.

Step 7 - Append to decisions.md: `DATE: [today] | PLAIN_SUMMARY | slop-gc | Identified [N] recurring patterns, proposed [M] lint rules, [K] confirmed for implementation.`

Step 8 - If steps 6-7 wrote governed files, run WORKFLOW-END COMMIT before returning control:
- `bash scripts/check.sh` — must exit 0 before proceeding
- Stage only files this command wrote — use `git add <file>...`. Do NOT use `git add -A`.
- `git status` — confirm what is staged matches the files this command wrote
- `git commit -m "chore(slop-gc): record recurring lint proposals"`
- `git status --porcelain` — if any listed files were written by this command, stop and fix. Unrelated dirty files are advisory only.
