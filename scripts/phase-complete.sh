#!/usr/bin/env bash
# scripts/phase-complete.sh — automated git workflow for phase transitions
# Post-implement (pending_review=true): commit → push branch
# Post-review (pending_review=false): merge main → push main → create next branch
set -euo pipefail

PENDING_REVIEW=$(bash scripts/state.sh get pending_review)
CURRENT_BRANCH=$(git branch --show-current)
NEXT_BRANCH="${1:-}"

recover() {
  echo "GIT-ERROR: $1"
  echo "Attempting recovery: $2"
  eval "$2" || { echo "ESCALATE: recovery failed — human intervention required"; exit 1; }
}

if [ "$PENDING_REVIEW" = "true" ]; then
  DIRTY=$(git status --porcelain | grep -v '^??' || true)
  if [ -n "$DIRTY" ]; then
    git add -A
    git commit -m "${CURRENT_BRANCH} complete" \
      || recover "commit failed" "git add -A && git commit -m '${CURRENT_BRANCH} complete'"
  fi
  git push origin "${CURRENT_BRANCH}" \
    || git push origin "${CURRENT_BRANCH}" --force-with-lease \
    || recover "push branch failed" "git fetch origin && git push origin ${CURRENT_BRANCH} --force-with-lease"
  echo "PHASE-COMPLETE: branch pushed. Switch provider and run /review."
else
  [ -z "$NEXT_BRANCH" ] && {
    echo "ERROR: next branch name required. Usage: bash scripts/phase-complete.sh <next-branch-name>"
    exit 1
  }
  git checkout main \
    || recover "checkout main failed" "git fetch origin && git checkout main"
  git merge "${CURRENT_BRANCH}" \
    || recover "merge failed" "git merge --no-ff ${CURRENT_BRANCH}"
  git push origin main \
    || recover "push main failed" "git pull --rebase origin main && git push origin main"
  git checkout -b "${NEXT_BRANCH}" \
    || recover "branch create failed" "git checkout -b ${NEXT_BRANCH}-$(date +%s)"
  git push origin "${NEXT_BRANCH}" \
    || recover "push new branch failed" "git push origin ${NEXT_BRANCH}"
  echo "PHASE-COMPLETE: merged to main. Now on ${NEXT_BRANCH}. Ready to implement."
fi
