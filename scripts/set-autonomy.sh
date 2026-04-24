#!/usr/bin/env bash
# scripts/set-autonomy.sh — set autonomy mode in state.json
# Usage: bash scripts/set-autonomy.sh [informed-yolo | full-yolo]
set -euo pipefail

MODE="${1:-}"
if [ "$MODE" = "full-yolo" ]; then
  if grep -Eq "^\s*-?\s*data_sensitivity:\s*sensitive\s*$" .ai-layer/PROJECT_CONFIG.md 2>/dev/null; then
    echo "ERROR: full-yolo mode is blocked because data_sensitivity is sensitive." >&2
    exit 1
  fi
fi
if [ -z "$MODE" ]; then
  echo "Usage: bash scripts/set-autonomy.sh [informed-yolo | full-yolo]"
  echo "Current: $(bash scripts/state.sh get autonomy)"
  exit 1
fi
case "$MODE" in
  informed-yolo|full-yolo) ;;
  *) echo "Invalid: $MODE. Valid: informed-yolo, full-yolo"; exit 1 ;;
esac

bash scripts/state.sh set autonomy "$MODE"

echo "Autonomy: $MODE"
case "$MODE" in
  informed-yolo) echo "Review stops active. Switch provider after each /implement." ;;
  full-yolo)     echo "Review stops disabled. DESIGN_STOP still fires." ;;
esac
