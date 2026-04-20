---
name: phase-complete
agent: mag
---
Run: bash scripts/phase-complete.sh [next-branch-name]

Provide next-branch-name only when review has just passed (pending_review=false).
Use kebab-case matching the devplan phase name, e.g. phase-6-commands-skills.

The script detects state automatically:
- pending_review=true → post-implement path (commit + push branch)
- pending_review=false → post-review path (merge main + push main + create next branch)

If the script outputs ESCALATE: report that line verbatim and stop.
Do not attempt any manual git commands.
