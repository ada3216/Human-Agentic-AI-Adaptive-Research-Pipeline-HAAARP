#!/usr/bin/env bash
# scripts/bootstrap.sh — first-time Magentica 2.0 setup
# Run once from the project root after cloning.
set -euo pipefail

echo "Magentica 2.0 bootstrap"
echo "─────────────────────────────────────────"

# 1. Git init if needed
if [ ! -d .git ]; then
  git init && git checkout -b main 2>/dev/null || true
  echo "✓ Git initialised"
else
  echo "✓ Git already initialised"
fi

# 2. npm install
# Node.js is required for the MCP memory server regardless of project language.
# Python-only projects still need Node.js for this one component.
if ! command -v node &>/dev/null; then
  echo "⚠ Node.js not found. Required for MCP memory server."
  echo "  Install: https://nodejs.org — then re-run bootstrap.sh"
  echo "  (Python projects still need Node.js for the memory server)"
fi
if [ -f package.json ]; then
  echo "Installing npm dependencies..."
  npm install --silent && echo "✓ npm install complete (versions pinned in package-lock.json)"
fi

# 3. Verify MCP memory server
if [ -f node_modules/@modelcontextprotocol/server-memory/dist/index.js ]; then
  echo "✓ MCP memory server available (local)"
else
  echo "⚠ MCP memory server not found — run: npm install"
fi

# 4. npm audit (advisory — surfaces known vulnerabilities in pinned dependencies)
echo "Running npm audit..."
npm audit --audit-level=high 2>/dev/null && echo "✓ npm audit passed" \
  || echo "⚠ npm audit found high-severity issues — run: npm audit for details"

# 5. Make scripts executable
chmod +x scripts/*.sh scripts/lint-adapters/*.sh 2>/dev/null || true
echo "✓ Scripts made executable"

# 6. State check
if [ -f .ai-layer/state.json ]; then
  bash scripts/state.sh validate 2>/dev/null && echo "✓ state.json valid" \
    || echo "⚠ state.json validation failed — run: bash scripts/state.sh validate"
else
  echo "⚠ state.json not found — run Phase 1 setup first"
fi

echo "─────────────────────────────────────────"
echo "Bootstrap complete."
echo "Next: open OpenCode, run /prime, then /project-init"
