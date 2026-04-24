---
name: plan
agent: planner
---
Before planning, run these checks in order:
  bash scripts/state.sh get pending_review
  If true: surface REVIEW_STOP (see mag.md format) and stop — do not plan until review completes.
  bash scripts/state.sh get design_stop_pending
  If true: surface the pending DESIGN_STOP question and stop.

If state is clear: invoke the planner with the task brief provided after /plan.
The planner produces .ai-layer/current-plan.md and fires DESIGN_STOPs if needed.

## WORKFLOW-END COMMIT (mandatory if /plan writes governed files directly)

Before returning control, run this sequence:
1. `bash scripts/check.sh` — must exit 0 before proceeding
2. Stage only files this command wrote — use `git add <file>...`. Do NOT use `git add -A`.
3. `git status` — confirm what is staged matches the files this command wrote
4. `git commit -m "[type]([scope]): [description]"` to produce a clean git commit
5. `git status --porcelain` — if any listed files were written by this command, stop and fix. Unrelated dirty files are advisory only.
