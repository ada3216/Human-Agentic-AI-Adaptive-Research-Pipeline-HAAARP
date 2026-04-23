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
If /plan edits governed files directly, end with a clean git commit before exit.
