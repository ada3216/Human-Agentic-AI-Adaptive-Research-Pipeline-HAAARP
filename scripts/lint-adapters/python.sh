#!/usr/bin/env bash
# Lint adapter: Python (Ruff)
# Reads *.ruff.toml rule files from .ai-layer/lint-rules/tier-1/
set -uo pipefail
RULES_DIR=".ai-layer/lint-rules/tier-1"

RUFF_STATUS=0

if command -v ruff &>/dev/null; then
  CONFIG=$(mktemp /tmp/ruff-XXXXXX.toml)
  trap 'rm -f "$CONFIG"' EXIT

  { echo "line-length = 120";
    echo "";
    for f in "$RULES_DIR"/*.ruff.toml; do
      [ -f "$f" ] && cat "$f"
    done
  } | sed '0,/^\[lint\]/{/^\[lint\]/a\
extend-select = ["EM101", "EM102", "EM103"]
}' > "$CONFIG"

  ruff check . --config "$CONFIG" 2>&1 || RUFF_STATUS=$?
else
  echo "SKIP: ruff not installed (pip install ruff)"
fi

if compgen -G "$RULES_DIR/*.pycheck.json" > /dev/null; then
  python3 scripts/lint-adapters/python_rules.py "$RULES_DIR" || exit 1
fi

[ "$RUFF_STATUS" -eq 0 ] || exit "$RUFF_STATUS"
