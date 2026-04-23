---
name: lint-evolve
agent: planner
---

You are proposing improvements to the active lint rule set based on
accumulated evidence. You do not implement anything. You produce a
proposals file for human review.

Read in full before producing anything:
- .ai-layer/lint-rules/tier-1/         (all rule files and .rules.md)
- .ai-layer/lint-rules/lint-failures.log
- .ai-layer/lint-rules/rejected-rules.md (do not re-propose anything here)
- .ai-layer/ARCHITECTURE.md
- .ai-layer/PROJECT_CONFIG.md
- All source files in governed_languages directories (read representative
  files — do not skip this step; rule quality depends on actual patterns)

Apply evidence threshold before proposing anything:
- Same rule fails ≥3 times in lint-failures.log, OR
- Same pattern visible in ≥3 source files with no current rule, OR
- ARCHITECTURE.md constraint with no corresponding rule

A proposal is NOT valid if:
- It duplicates an existing rule
- It is not checkable by the language's lint tool
- It has no repo-specific evidence (general best practice alone is
  insufficient)
- It appears in rejected-rules.md

Check the rule cap (15 active rules per governed language) before
proposing additions. If at the cap, proposals must include a merge
or replacement rationale.

For each valid proposal, write one entry to
`.ai-layer/lint-rules/proposals.md`:

---
proposal: <language>-<category>-<descriptor>
category: <Factory category from DP-3>
evidence: <log lines or source:line references that ground this>
rule_content: |
  <exact content of the tool config file>
rules_md_content: |
  <exact content of the .rules.md file, following P7-3 structure>
status: PROPOSED
---

Then emit a DESIGN_STOP:

DESIGN_STOP
Lint rule proposals written to .ai-layer/lint-rules/proposals.md.
[N] proposals grounded in: [log entries / source patterns /
ARCHITECTURE.md gaps].

For each proposal reply: APPROVE, REJECT <reason>, or DEFER.
APPROVE — executor implements in next session.
REJECT  — reason recorded in rejected-rules.md; will not be re-proposed.
DEFER   — stays in proposals.md for next /lint-evolve run.
If this command edits governed files directly, end with a clean git commit before exit.
