#!/usr/bin/env bash
# scripts/session-start.sh — environment health check (human-run)
set -uo pipefail
PASS=0; FAIL=0

check() { if eval "$2" 2>/dev/null; then echo "PASS $1"; PASS=$((PASS+1));
  else echo "FAIL $1"; FAIL=$((FAIL+1)); fi; }

# state.json validate runs first — surfaces schema issues with a clear remediation path.
echo "── state.json ──"
bash scripts/state.sh validate || echo "  (run: bash scripts/state.sh migrate)"
echo ""

check "state.json"           "[ -f .ai-layer/state.json ]"
check "state.json valid"     "python3 -c \"import json; json.load(open('.ai-layer/state.json'))\""
check "decisions.md"         "[ -f .ai-layer/decisions.md ]"
check "PROJECT_CONFIG.md"    "[ -f .ai-layer/PROJECT_CONFIG.md ]"
check "lint-check.sh"        "[ -f scripts/lint-check.sh ]"
check "gatekeeper.js"        "[ -f .opencode/plugins/gatekeeper.js ]"

echo ""
python3 - << 'PYEOF'
import json
s = json.load(open(".ai-layer/state.json"))
if s.get("pending_review"):
    print("NOTE: REVIEW_STOP pending — switch to a different provider before /review")
if s.get("design_stop_pending"):
    q = s.get("design_stop_question", "(none)")
    print(f"NOTE: DESIGN_STOP pending: {q}")
if not s.get("pending_review") and not s.get("design_stop_pending"):
    print("State: clean — no pending stops")
PYEOF

echo ""
echo "session-start: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
