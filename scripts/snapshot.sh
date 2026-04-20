#!/usr/bin/env bash
# scripts/snapshot.sh — git checkpoint before structural changes
# NOTE: This script runs git commit --allow-empty directly (not through OpenCode).
# This is intentional — it is host-level infrastructure, not an agent-initiated commit.
# Gate 2 covers agent-initiated commits via OpenCode tooling; this script operates
# outside that boundary by design.
set -euo pipefail

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MSG="snapshot: pre-structural-change $TIMESTAMP"

if ! git diff --quiet HEAD 2>/dev/null || [ -n "$(git status --porcelain)" ]; then
  git stash push -m "$MSG"
  echo "snapshot: stashed — $MSG"
  echo "Restore with: git stash pop"
else
  git commit --allow-empty -m "$MSG"
  echo "snapshot: checkpoint commit — $MSG"
  echo "Roll back with: git revert HEAD --no-edit"
fi
