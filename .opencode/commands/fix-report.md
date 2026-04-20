---
name: fix-report
agent: executor
---
Analyse a test failure report, error trace, or stack trace provided by the human.
Produce a structured diagnosis. Do NOT implement the fix.

ROOT CAUSE: [one sentence — what failed and why]
AFFECTED: [file(s) and function(s) most likely involved]
LIKELY FIX: [plain language — what needs to change]
CONFIRM BEFORE FIXING:
  - [question 1 the human should verify first]
  - [question 2 if relevant]
RISK: [LOW | MEDIUM | HIGH] — risk of fix causing unintended side effects

End with: Run /plan "[brief fix description]" to implement this fix.
