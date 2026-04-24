#!/usr/bin/env bash
# scripts/check.sh — Gate 2 pre-commit check suite
set -uo pipefail
FAIL=0

section() { echo ""; echo "── $1 ──"; }

section "Lint"
if [ -f scripts/lint-check.sh ]; then
  bash scripts/lint-check.sh || { echo "FAIL: lint"; FAIL=$((FAIL+1)); }
else
  echo "SKIP: lint-check.sh absent — run /project-init first"
fi

section "Size limits"
if [ -f scripts/size-check.sh ]; then
  bash scripts/size-check.sh || { echo "FAIL: size limits"; FAIL=$((FAIL+1)); }
else
  echo "SKIP: size-check.sh absent"
fi

section "Secrets"
if command -v gitleaks &>/dev/null; then
  gitleaks detect --no-git --source . --exit-code 1 2>/dev/null \
    || { echo "FAIL: secrets scan"; FAIL=$((FAIL+1)); }
else
  if grep -Eq "^\s*-?\s*data_sensitivity:\s*sensitive\s*$" .ai-layer/PROJECT_CONFIG.md 2>/dev/null; then
    echo "FAIL: gitleaks is required for sensitive projects."
    FAIL=$((FAIL+1))
  else
    echo "WARN: gitleaks not installed — secrets scan skipped. Install: brew install gitleaks"
    echo "      Credentials in source files are not being checked before commits."
  fi
fi

section "Lockfile integrity"
if [ -f package-lock.json ] || [ -f poetry.lock ]; then
  if ! git diff --quiet -- package-lock.json poetry.lock 2>/dev/null; then
    if grep -Eq "^\s*-?\s*data_sensitivity:\s*sensitive\s*$" .ai-layer/PROJECT_CONFIG.md 2>/dev/null; then
      echo "FAIL: lockfile changed in a sensitive project without /freeze-audit"
      FAIL=$((FAIL+1))
    else
      echo "WARN: lockfiles modified. Ensure dependencies are reviewed."
    fi
  else
    echo "PASS: lockfiles unchanged."
  fi
else
  echo "SKIP: no lockfiles."
fi

section "Integrity"
if [ -f scripts/verify-integrity.sh ]; then
  bash scripts/verify-integrity.sh check || { echo "FAIL: governance file integrity"; FAIL=$((FAIL+1)); }
else
  echo "SKIP: verify-integrity.sh absent — created in Phase 3"
fi

section "Tests (JS/TS)"
if [ -f package.json ] && python3 -c \
  "import json; d=json.load(open('package.json')); exit(0 if 'test' in d.get('scripts',{}) else 1)" 2>/dev/null; then
  npm test --silent 2>/dev/null || { echo "FAIL: npm test"; FAIL=$((FAIL+1)); }
else
  echo "SKIP: no npm test script"
fi

section "Tests (Python)"
if [ -d tests ]; then
  MOCK_LLM=true python3 -m pytest tests/ --tb=short -q || { echo "FAIL: pytest"; FAIL=$((FAIL+1)); }
else
  echo "SKIP: no tests directory"
fi

echo ""
echo "check.sh: $FAIL failure(s)"
[ "$FAIL" -eq 0 ]
