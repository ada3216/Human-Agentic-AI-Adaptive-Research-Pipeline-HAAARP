#!/usr/bin/env bash
# snapshot.sh
# Creates a labelled git stash before any risky operation.
# Agents should call this before STRUCTURAL changes.
# Usage: bash scripts/snapshot.sh "label describing what you're about to do"
# Restore: git stash list → git stash pop (or git stash apply stash@{n})

set -e

LABEL="${1:-manual}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
STASH_MSG="snapshot: $LABEL — $TIMESTAMP"

# Check there is something to snapshot
if git diff --quiet && git diff --cached --quiet && \
   [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "→ Working tree is clean — nothing to snapshot."
  echo "→ Proceed. No restore point needed for a clean tree."
else
  git stash push --include-untracked -m "$STASH_MSG"
  echo "→ Snapshot saved: $STASH_MSG"
fi

echo ""
echo "To restore this snapshot:"
echo "  git stash list                  # find the stash index"
echo "  git stash apply stash@{0}       # restore without dropping"
echo "  git stash pop                   # restore and drop"
echo ""
echo "To discard (if all went well):"
echo "  git stash drop stash@{0}"
