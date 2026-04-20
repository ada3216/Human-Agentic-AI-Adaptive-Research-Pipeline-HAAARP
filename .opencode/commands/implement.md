---
name: implement
agent: executor
---
Before implementing, run these checks in order:
  bash scripts/state.sh get design_stop_pending
  If true: surface the pending DESIGN_STOP question and stop.
  Check .ai-layer/current-plan.md exists.
  If not: tell human to run /plan first and stop.

If all checks clear: invoke the executor to implement .ai-layer/current-plan.md.
