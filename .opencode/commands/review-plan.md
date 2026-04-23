---
name: review-plan
agent: reviewer
---
Plan review gate. Runs after /plan completes and before /implement.
Human switches to a different AI provider and runs /review-plan.

This command uses the reviewer agent in PLAN REVIEW MODE:
- Do NOT run the normal /review flow.
- Do NOT require pending_review=true.
- Do NOT read git diff.
- Review .ai-layer/current-plan.md only.

Preflight:
1. Run: `bash scripts/state.sh get plan_review_pending`
   - If `false`: report "No plan review pending. Run /plan first." and stop.
2. Check that `.ai-layer/current-plan.md` exists.
   - If missing: report "Missing .ai-layer/current-plan.md. Run /plan first." and stop.

Review rubric (apply to current-plan.md only):
1. Soundness of approach — does the strategy make sense given the codebase?
2. Completeness of implementation steps — are all necessary changes listed?
3. Acceptance criteria are bash-verifiable — can each criterion be checked with a shell command?
4. Scope correctness — does the plan match the requested task, no more, no less?
5. Missing considerations — dependencies, risk, edge cases, rollback paths?

Decision outcomes:

A) APPROVED (no issues)
- Run: `bash scripts/state.sh set plan_review_pending false`
- Append to decisions.md:
  `DATE: [today] | PLAN_REVIEW_PASS | [task name from plan] | no issues`
- Output:
  ```
  PLAN_REVIEW_OUTCOME: APPROVED
  Summary: [1-3 concise bullets]
  ```
- Instruct human: run /implement in this same session.

B) APPROVED_WITH_MINOR_FIXES
- Apply minor fixes directly in .ai-layer/current-plan.md.
- Run commit sequence (mandatory — reviewer edited governed files):
  1. `git add -A`
  2. `bash scripts/check.sh`
  3. `git commit -m "fix(plan): [brief description of corrections]"`
     - Conventional commit: type(scope): description, present tense, under 72 chars
  4. If `git status --porcelain` is non-empty after commit, surface:
     ```
     RESIDUAL UNCOMMITTED FILES:
     [porcelain output]
     ```
- Run: `bash scripts/state.sh set plan_review_pending false`
- Append to decisions.md:
  `DATE: [today] | PLAN_REVIEW_PASS | [task name] | minor fixes applied: [summary]`
- Output:
  ```
  PLAN_REVIEW_OUTCOME: APPROVED_WITH_MINOR_FIXES
  Summary: [what was corrected]
  ```
- Instruct human: run /implement in this same session.

C) MAJOR_ISSUES
- Do NOT edit files.
- Keep: plan_review_pending=true
- Append to decisions.md:
  `DATE: [today] | PLAN_REVIEW_FAIL | [task name] | [N] major issues`
- Output:
  ```
  PLAN_REVIEW_OUTCOME: MAJOR_ISSUES
  Items:
  1. [specific issue]
  2. [specific issue]
  ```
- Ask human to choose:
  1) Return to LLM A and run /plan to re-plan
  2) Proceed anyway
- If human chooses proceed anyway:
  - Run: `bash scripts/state.sh set plan_review_pending false`
  - Append to decisions.md:
    `DATE: [today] | PLAN_REVIEW_OVERRIDE | [task name] | human chose to proceed despite major issues`
  - Output warning and instruct human to run /implement.

Required NEXT STEP footer:
```
─────────────────────────────────────────
NEXT STEP
Command:  /implement
Action:   Review the plan above. Run /implement to proceed.
─────────────────────────────────────────
```
