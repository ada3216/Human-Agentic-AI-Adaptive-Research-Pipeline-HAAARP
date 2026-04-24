---
name: implement
agent: executor
---
Before implementing, run these checks in order:
  bash scripts/state.sh get plan_review_pending
  If true: report "Plan review pending. Run /review-plan first (on a different provider)." and stop.
  bash scripts/state.sh get design_stop_pending
  If true: surface the pending DESIGN_STOP question and stop.
  Check .ai-layer/current-plan.md exists.
  If not: tell human to run /plan first and stop.

If all checks clear: invoke the executor to implement .ai-layer/current-plan.md.

The executor's WORKFLOW-END COMMIT block is mandatory for `/implement`.
If this command flow edits governed files directly before handoff, run the same sequence:
1. `bash scripts/check.sh` — must exit 0 before proceeding
2. Stage only files this command wrote — use `git add <file>...`. Do NOT use `git add -A`.
3. `git status` — confirm what is staged matches the files this command wrote
4. `git commit -m "[type]([scope]): [description]"` to produce a clean git commit
5. `git status --porcelain` — if any listed files were written by this command, stop and fix. Unrelated dirty files are advisory only.
