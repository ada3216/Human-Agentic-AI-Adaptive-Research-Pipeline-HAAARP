#!/usr/bin/env bash
# preflight.sh
# Run before any coding session begins.
# Checks that the governance structure is in place and tools are available.
# code.agent should call this at the start of Step 0.
# Usage: bash scripts/preflight.sh [--structural]
#   --structural  also enforces that a snapshot has been taken recently

set -e

STRUCTURAL=false
[ "$1" = "--structural" ] && STRUCTURAL=true

PASS=true
WARNINGS=()
FAILURES=()

echo "→ Running pre-flight checks..."
echo ""

# --- Required governance files ---
required_files=(
  "REPO.context.md"
  "CHANGES.md"
  "docs/guardrails/baseline.md"
  "docs/tests/plan.md"
  "docs/invariants.md"
  "docs/incidents.md"
)

for f in "${required_files[@]}"; do
  if [ ! -f "$f" ]; then
    FAILURES+=("MISSING: $f — run @init first")
    PASS=false
  fi
done

# --- current-plan.md check ---
if [ ! -f "current-plan.md" ]; then
  FAILURES+=("MISSING: current-plan.md — code.agent must write the plan before implementing")
  PASS=false
else
  # Check it has been filled in (not just the template)
  if grep -q "YYYY-MM-DD" current-plan.md; then
    FAILURES+=("INCOMPLETE: current-plan.md still contains template placeholders — fill it in first")
    PASS=false
  fi
  # Check STATUS field
  status=$(grep "^STATUS:" current-plan.md | head -1 | awk -F': ' '{print $2}' | tr -d '[:space:]')
  if [ "$status" = "COMPLETE" ] || [ "$status" = "ABANDONED" ]; then
    WARNINGS+=("WARNING: current-plan.md STATUS is $status — start a new plan for this task")
  fi
  # Check RISK LEVEL for snapshot enforcement
  risk=$(grep "^RISK LEVEL:" current-plan.md | head -1 | awk -F': ' '{print $2}' | tr -d '[:space:]')
  if [ "$risk" = "STRUCTURAL" ] || [ "$STRUCTURAL" = "true" ]; then
    # Check if a snapshot was taken recently (stash list)
    recent_snapshot=$(git stash list 2>/dev/null | grep "snapshot:" | head -1)
    if [ -z "$recent_snapshot" ]; then
      FAILURES+=("REQUIRED: STRUCTURAL change detected but no snapshot found — run: bash scripts/snapshot.sh \"[label]\"")
      PASS=false
    else
      echo "  ✓ Snapshot found: $(echo "$recent_snapshot" | cut -d: -f3- | xargs)"
    fi
  fi
fi

# --- Mechanical tool availability ---
tools_checked=false

# Node/JS project
if [ -f "package.json" ]; then
  tools_checked=true
  command -v npx >/dev/null 2>&1 || WARNINGS+=("WARNING: npx not found — lint/type checks may not run")
  # Check for eslint
  if [ -f ".eslintrc*" ] || [ -f "eslint.config*" ] || grep -q '"eslint"' package.json 2>/dev/null; then
    echo "  ✓ ESLint configured"
  else
    WARNINGS+=("WARNING: No ESLint config found — lint checks will be skipped")
  fi
  # Check for TypeScript
  if [ -f "tsconfig.json" ]; then
    echo "  ✓ TypeScript configured"
  fi
  # Check for test runner
  if grep -q '"jest"\|"vitest"\|"mocha"' package.json 2>/dev/null; then
    echo "  ✓ Test runner configured"
  else
    WARNINGS+=("WARNING: No test runner found in package.json")
  fi
fi

# Python project
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  tools_checked=true
  command -v python3 >/dev/null 2>&1 || FAILURES+=("MISSING: python3 not found")
  # Check for pytest
  if command -v pytest >/dev/null 2>&1 || grep -q "pytest" pyproject.toml 2>/dev/null; then
    echo "  ✓ pytest available"
  else
    WARNINGS+=("WARNING: pytest not found — test step will fail")
  fi
  # Check for ruff or flake8
  if command -v ruff >/dev/null 2>&1 || command -v flake8 >/dev/null 2>&1; then
    echo "  ✓ Python linter available"
  else
    WARNINGS+=("WARNING: No Python linter found (ruff or flake8) — lint checks will be skipped")
  fi
fi

if [ "$tools_checked" = false ]; then
  WARNINGS+=("WARNING: Could not detect project type — run bash scripts/probe-stack.sh first")
fi

# --- Git state check ---
current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
  FAILURES+=("BRANCH: Currently on $current_branch — create a feature branch before implementing")
  PASS=false
else
  echo "  ✓ Branch: $current_branch"
fi

# --- REPO.context.md Stack section populated ---
if [ -f "REPO.context.md" ]; then
  if grep -q "not yet detected\|unknown" REPO.context.md 2>/dev/null; then
    WARNINGS+=("WARNING: REPO.context.md Stack section has unknown fields — run: bash scripts/probe-stack.sh")
  else
    echo "  ✓ Stack section populated"
  fi
fi

# --- Output results ---
echo ""

if [ ${#FAILURES[@]} -gt 0 ]; then
  echo "✗ PRE-FLIGHT FAILED"
  echo ""
  for f in "${FAILURES[@]}"; do
    echo "  ✗ $f"
  done
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo ""
  echo "⚠ Warnings (non-blocking):"
  for w in "${WARNINGS[@]}"; do
    echo "  ⚠ $w"
  done
fi

echo ""

if [ "$PASS" = true ]; then
  echo "✓ PRE-FLIGHT PASSED — safe to begin implementation"
  exit 0
else
  echo "Fix the failures above before proceeding."
  exit 1
fi
