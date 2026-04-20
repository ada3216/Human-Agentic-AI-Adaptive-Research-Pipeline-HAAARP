---
name: commit
agent: executor
---
Note: as of v1.2, /implement commits as part of implement_complete. /commit is
retained for manual or recovery use — committing follow-up edits, fixing a commit
message, or recovering from a partial implementation that did not reach
implement_complete cleanly.

Run: bash scripts/check.sh
If it fails: report which check failed and stop. Do not commit.

If check.sh passes:
  git add -A
  git commit -m "[type(scope): description]"
  Conventional commit types: feat | fix | refactor | docs | chore
  Description: present tense, under 72 characters.
  Gate 2 in gatekeeper.ts runs automatically on the commit call.
  Report the commit hash on success.
