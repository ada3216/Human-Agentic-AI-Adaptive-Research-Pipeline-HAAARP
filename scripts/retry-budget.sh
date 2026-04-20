#!/usr/bin/env bash
# scripts/retry-budget.sh — per-issue three-strike retry budget
#
# Usage:
#   bash scripts/retry-budget.sh "<issue-id>"         increment and check
#   bash scripts/retry-budget.sh "<issue-id>" reset    clear counter
#
# Exit: 0 = budget remaining | 1 = exhausted, escalate | 2 = usage error
set -euo pipefail

COUNTS_FILE=".ai-layer/retry-counts.json"
MAX=3
ISSUE="${1:-}"
ACTION="${2:-increment}"

[ -z "$ISSUE" ] && { echo "ERROR: issue-id required"; exit 2; }
[ -f "$COUNTS_FILE" ] || echo '{}' > "$COUNTS_FILE"

if [ "$ACTION" = "reset" ]; then
  python3 - "$ISSUE" "$COUNTS_FILE" << 'PYEOF'
import json, sys
issue, counts_file = sys.argv[1], sys.argv[2]
d = json.load(open(counts_file))
if issue in d:
    del d[issue]
    json.dump(d, open(counts_file, 'w'), indent=2)
print(f"retry-budget: reset for {issue}")
PYEOF
  exit 0
fi

python3 - "$ISSUE" "$COUNTS_FILE" "$MAX" << 'PYEOF'
import json, sys
issue, counts_file, max_retries = sys.argv[1], sys.argv[2], int(sys.argv[3])
d = json.load(open(counts_file))
d[issue] = d.get(issue, 0) + 1
count = d[issue]
json.dump(d, open(counts_file, 'w'), indent=2)
if count >= max_retries:
    print(f"RETRY_BUDGET: 0 — ESCALATE. {count} attempts on: {issue}")
    sys.exit(1)
else:
    remaining = max_retries - count
    print(f"RETRY_BUDGET: {remaining} remaining for: {issue} (attempt {count} of {max_retries})")
    sys.exit(0)
PYEOF
