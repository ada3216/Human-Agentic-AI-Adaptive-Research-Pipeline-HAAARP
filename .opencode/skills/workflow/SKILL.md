# Workflow Skill — Magentica 2.0 Reference

## The informed-yolo cycle

```
/plan [brief]       DESIGN_STOP(s) if needed        current-plan.md        PLAN_REVIEW_GATE
/review-plan        (on different AI provider)       PLAN_REVIEW_OUTCOME: APPROVED or MAJOR_ISSUES
/implement          Gate 1 lint feedback             retry-budget if needed        REVIEW_STOP
/review             (on different AI provider)       REVIEW OUTCOME: PASS or FAIL
/plan [next phase]  repeat
```

In full-yolo mode: REVIEW_STOP is skipped. DESIGN_STOP still fires.

## DESIGN_STOP format and state transitions

Format:
```
DESIGN_STOP
Decision: [one sentence describing the choice]
Why this matters: [one sentence — how the answer changes implementation]
Options:
  1. [what gets built if chosen]
  2. [alternative]
  N. Other — type your own instruction.
```

State on fire:   design_stop_pending=true, design_stop_question=[question], phase=design_stop
State on answer: design_stop_pending=false, design_stop_question=null, phase=planning
Log on answer:   DATE: [today] | DESIGN_DECISION | [decision] | chosen: [answer]

`/project-init` exception:
- In informed-yolo, unresolved setup decisions are batched into one DESIGN_STOP block with numbered items.
- For other planning tasks, keep one-stop-per-decision behavior.

## REVIEW_STOP format and state transitions

Format (from mag.md):
```
REVIEW_STOP
Phase complete: [current_task]
Implement slot was: [A|B]

Next steps:
1. Open a new session with a DIFFERENT AI provider (strong default)
2. Run: /review
3. PASS → return here, /plan next phase
4. FAIL → return here, fix items, /implement again
```

State on fire:   pending_review=true, implement_slot flipped
State on PASS:   pending_review=false
Log on PASS:     DATE: [today] | REVIEW_PASS | [task name] | slot [slot]
Log on FAIL:     DATE: [today] | REVIEW_FAIL | [task name] | [N] items | slot [slot]

## PLAN_REVIEW_GATE format and state transitions

Format (from mag.md):
```
PLAN_REVIEW_GATE
Plan produced: [current_task]

Next steps:
1. Open a new session with a DIFFERENT AI provider (strong default)
2. Run: /review-plan
3. APPROVED or APPROVED_WITH_MINOR_FIXES → run /implement in same session
4. MAJOR_ISSUES → return to original provider and /plan, or proceed anyway
```

State on fire:     plan_review_pending=true (set by planner after producing current-plan.md)
State on APPROVED: plan_review_pending=false
Log on APPROVED:   DATE: [today] | PLAN_REVIEW_PASS | [task name] | [summary]
Log on MAJOR:      DATE: [today] | PLAN_REVIEW_FAIL | [task name] | [N] major issues

## state.json field reference

| Field | Type | Meaning |
|---|---|---|
| schema_version | int | Increment when adding fields. Never remove. |
| phase | string | idle / planning / implementing / design_stop |
| autonomy | string | informed-yolo / full-yolo |
| implement_slot | string | "A" or "B" — audit marker for rotation flow, no provider identity info |
| pending_review | bool | true: review pending; cannot plan or implement |
| current_task | string/null | Active task description |
| last_completed_phase | string/null | Last task the executor finished implementing (set at implement_complete, before review) |
| design_stop_pending | bool | true: question awaiting human answer |
| design_stop_question | string/null | The pending question text |
| plan_review_pending | bool | true: plan review gate active; /implement blocked until /review-plan clears it |

All reads and writes: `bash scripts/state.sh [get|set|show]`

## decisions.md entry format

```
DATE: [ISO date] | [TYPE] | [content]
```

| Type | When appended |
|---|---|
| INIT | Project or Magentica initialised |
| PLAN | Plan produced |
| DESIGN_DECISION | DESIGN_STOP resolved |
| IMPLEMENT | Phase implementation complete |
| REVIEW_PASS | Reviewer approved |
| REVIEW_FAIL | Reviewer found issues |
| PLAN_REVIEW_PASS | Plan review approved (clean or with minor fixes) |
| PLAN_REVIEW_FAIL | Plan review found major issues |
| PLAN_REVIEW_OVERRIDE | Human chose to proceed despite major plan issues |
| PLAIN_SUMMARY | Reviewer appends after every REVIEW_PASS — non-technical summary of what was built |
| ESCALATION | Retry budget exhausted |
| AUTO_RESET | Stale phase cleared at session start |
| MODEL_CONFIG | `/set-model` configured a custom model for a role |
| REVIEW_ATTEST | `/review` attestation for provider switch and override reason |
| ARCHIVE | `/summarize-decisions` summary block for compacted entries |
| COMPACTION | decisions.md compacted by /summarize-decisions |
| FREEZE_AUDIT | `/freeze-audit` run before a study deployment tag |

## PLAIN_SUMMARY entries and ethics board use

PLAIN_SUMMARY entries are written by the reviewer after every REVIEW_PASS, in non-technical
language, describing what was built and why. These entries are intentionally readable by
someone with no coding background. They constitute the human-readable audit trail of
development decisions.

When preparing for ethics board review: the PLAIN_SUMMARY entries from decisions.md
are the primary evidence of what the tool does and how it was governed. They were written
contemporaneously by an independent AI reviewer (different provider from the implementor),
not retrospectively by the developer. This provenance is what distinguishes them from a
developer-written description.

The /freeze-audit command compiles these entries into a single submission-ready record.

## retry-budget.sh calling convention

```bash
bash scripts/retry-budget.sh "[issue-id]"
# Exit 0: budget remaining (proceed with retry)
# Exit 1: exhausted — surface ESCALATION, stop
bash scripts/retry-budget.sh "[issue-id]" reset
# Clears the counter for this issue
```

Stable issue-id examples: `lint:src/api.ts`, `test:unit-auth`, `check:secrets`

## Memory write points — three only

1. After implement_complete (workflow, every cycle): delete previous `last_task` entity, create new one with task name, outcome, and date.
2. After DESIGN_STOP answer that produces a binding architectural constraint (workflow, as needed): create entity tagged `architectural_decision`.
3. During `/project-init` (one-time setup, per confirmed lint rule): create entity tagged `constraint`.

No other writes to MCP memory under any circumstances. After `/project-init` has run, only the two workflow points fire on an ongoing basis.

## The rule about stop types

Two stop types: DESIGN_STOP (design decision) and REVIEW_STOP (phase complete).
One plan review gate: PLAN_REVIEW_GATE (plan produced, awaiting cross-provider review before /implement).
PLAN_REVIEW_GATE is not a stop type — it is a routing gate that blocks /implement until
the plan has been reviewed on a different provider via /review-plan. It uses a boolean
flag (plan_review_pending) rather than a new phase value.
ESCALATION is not a stop type — it is a budget-exhaustion report.
Use DESIGN_STOP, REVIEW_STOP, PLAN_REVIEW_GATE, or ESCALATION.
A new stop type requires a new version of this specification.

## Full command list

| Command | Agent | Purpose |
|---|---|---|
| /plan | planner | Produce current-plan.md, fire DESIGN_STOPs |
| /implement | executor | Implement current-plan.md |
| /review | reviewer | Review on different provider |
| /review-plan | reviewer | Plan review on different provider (before /implement) |
| /commit | executor | Manual escape hatch: check.sh + git commit |
| /prime | executor | PRIME CONTEXT block |
| /probe | executor | Detect verbosity, write compensating constraints |
| /project-init | planner | Set up project, configure lint rules |
| /brownfield-audit | reviewer | Governance readiness report |
| /set-autonomy | mag | Switch autonomy mode (wraps scripts/set-autonomy.sh) |
| /set-model | mag | Configure custom_models in PROJECT_CONFIG.md |
| /cold-review | reviewer | Rate any file/diff: architecture, security, readability, sensitive data |
| /fix-report | executor | Structured diagnosis of a failure or error trace |
| /summarize-decisions | executor | Compact old decisions.md entries |
| /freeze-audit | reviewer | Produce FREEZE AUDIT RECORD |
