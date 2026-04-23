---
name: commit
agent: executor
---
Manual escape hatch only — not part of automated workflow.

As of v1.2, commits are embedded in the agents that write files:
- executor: commits as part of implement_complete
- reviewer: commits when applying fixes (e.g., /review-plan minor corrections)
- project-init: commits after writing config/rules/docs

Use /commit only when the human needs to commit outside normal flow:
recovering from a partial implementation, committing follow-up edits,
or fixing a commit message.

Run: bash scripts/check.sh
If it fails: report which check failed and stop. Do not commit.

If check.sh passes:
  git add -A
  git commit -m "[type(scope): description]"
  Conventional commit types: feat | fix | refactor | docs | chore
  Description: present tense, under 72 characters.
  Gate 2 in gatekeeper.ts runs automatically on the commit call.
  Report the commit hash on success.
  If git status --porcelain is non-empty after commit: surface residual files.
