#!/usr/bin/env bash
# probe-stack.sh
# Detects project stack and updates REPO.context.md Stack section.
# Run once after @init, then re-run after major dependency changes.
# Usage: bash scripts/probe-stack.sh

set -e

CONTEXT_FILE="REPO.context.md"

if [ ! -f "$CONTEXT_FILE" ]; then
  echo "ERROR: $CONTEXT_FILE not found. Run @init first."
  exit 1
fi

echo "→ Probing stack..."

# --- Language detection ---
LANGUAGE="unknown"
[ -f "package.json" ]        && LANGUAGE="JavaScript/TypeScript"
[ -f "pyproject.toml" ]      && LANGUAGE="Python"
[ -f "requirements.txt" ]    && LANGUAGE="Python"
[ -f "Cargo.toml" ]          && LANGUAGE="Rust"
[ -f "go.mod" ]              && LANGUAGE="Go"
[ -f "pom.xml" ]             && LANGUAGE="Java"

# --- Framework detection (most specific first to prevent overwrite) ---
FRAMEWORK="unknown"
if [ -f "package.json" ]; then
  # Check specific before generic — Next.js > React, Fastify > Express
  grep -q '"next"'    package.json && FRAMEWORK="Next.js"
  [ "$FRAMEWORK" = "unknown" ] && grep -q '"nuxt"'    package.json && FRAMEWORK="Nuxt"
  [ "$FRAMEWORK" = "unknown" ] && grep -q '"fastify"' package.json && FRAMEWORK="Fastify"
  [ "$FRAMEWORK" = "unknown" ] && grep -q '"express"' package.json && FRAMEWORK="Express"
  [ "$FRAMEWORK" = "unknown" ] && grep -q '"vue"'     package.json && FRAMEWORK="Vue"
  [ "$FRAMEWORK" = "unknown" ] && grep -q '"react"'   package.json && FRAMEWORK="React"
fi
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  # FastAPI before Flask — more specific
  grep -rq "fastapi"  requirements*.txt pyproject.toml 2>/dev/null && FRAMEWORK="FastAPI"
  [ "$FRAMEWORK" = "unknown" ] && grep -rq "django" requirements*.txt pyproject.toml 2>/dev/null && FRAMEWORK="Django"
  [ "$FRAMEWORK" = "unknown" ] && grep -rq "flask"  requirements*.txt pyproject.toml 2>/dev/null && FRAMEWORK="Flask"
fi

# --- Test runner detection ---
TEST_RUNNER="none detected"
[ -f "jest.config.*" ]        && TEST_RUNNER="Jest"
[ -f "vitest.config.*" ]      && TEST_RUNNER="Vitest"
[ -f "pytest.ini" ]           && TEST_RUNNER="pytest"
[ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null && TEST_RUNNER="pytest"
[ -f "package.json" ] && grep -q '"vitest"' package.json && TEST_RUNNER="Vitest"
[ -f "package.json" ] && grep -q '"jest"'   package.json && TEST_RUNNER="Jest"

# --- ORM/DB detection ---
DB="none detected"
if [ -f "package.json" ]; then
  grep -q '"prisma"'   package.json && DB="Prisma"
  grep -q '"drizzle"'  package.json && DB="Drizzle"
  grep -q '"mongoose"' package.json && DB="Mongoose/MongoDB"
  grep -q '"pg"'       package.json && DB="PostgreSQL (pg)"
  grep -q '"sqlite3"'  package.json && DB="SQLite"
fi
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  grep -rq "sqlalchemy" requirements*.txt pyproject.toml 2>/dev/null && DB="SQLAlchemy"
  grep -rq "django.db"  requirements*.txt pyproject.toml 2>/dev/null && DB="Django ORM"
fi

# --- Package manager detection ---
PKG_MANAGER="unknown"
[ -f "package-lock.json" ] && PKG_MANAGER="npm"
[ -f "yarn.lock" ]         && PKG_MANAGER="yarn"
[ -f "pnpm-lock.yaml" ]    && PKG_MANAGER="pnpm"
[ -f "bun.lockb" ]         && PKG_MANAGER="bun"
[ -f "uv.lock" ]           && PKG_MANAGER="uv"

# --- TypeScript detection ---
TS=""
[ -f "tsconfig.json" ] && TS=" + TypeScript"

# --- Coverage threshold (check config files) ---
COVERAGE_THRESHOLD="70 (default)"
if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
  threshold=$(grep -h "branches\|lines\|statements" jest.config.* 2>/dev/null | grep -o '[0-9]\+' | head -1)
  [ -n "$threshold" ] && COVERAGE_THRESHOLD="$threshold (from jest config)"
fi

echo ""
echo "Detected stack:"
echo "  Language:      $LANGUAGE$TS"
echo "  Framework:     $FRAMEWORK"
echo "  Test runner:   $TEST_RUNNER"
echo "  Database/ORM:  $DB"
echo "  Package mgr:   $PKG_MANAGER"
echo "  Coverage min:  $COVERAGE_THRESHOLD%"
echo ""

# --- Write non-destructive probe results to REPO.context.md ---
# Preserve any repo-specific Stack notes written by @init or by humans.
PROBE_BLOCK="### Autodetect probe
- Language: $LANGUAGE$TS
- Framework: $FRAMEWORK
- Test framework: $TEST_RUNNER
- Database/ORM: $DB
- Package manager: $PKG_MANAGER
- Coverage threshold: $COVERAGE_THRESHOLD%
- Last probed: $(date +%Y-%m-%d)
### End autodetect probe"

awk -v block="$PROBE_BLOCK" '
  BEGIN { in_stack=0; skip_probe=0; inserted=0 }

  function print_probe() {
    if (!inserted) {
      if (last_printed_blank == 0) {
        print ""
      }
      print block
      inserted=1
      last_printed_blank=0
    }
  }

  /^## Stack$/ {
    in_stack=1
    print
    last_printed_blank=0
    next
  }

  /^## / {
    if (in_stack) {
      print_probe()
      in_stack=0
    }
    skip_probe=0
    print
    last_printed_blank=0
    next
  }

  in_stack && /^### Autodetect probe$/ {
    skip_probe=1
    next
  }

  skip_probe {
    if ($0 == "### End autodetect probe") {
      skip_probe=0
    }
    next
  }

  {
    print
    last_printed_blank = ($0 == "")
  }

  END {
    if (in_stack) {
      print_probe()
    }
  }
' "$CONTEXT_FILE" > "$CONTEXT_FILE.tmp" && mv "$CONTEXT_FILE.tmp" "$CONTEXT_FILE"

echo "→ REPO.context.md probe results appended under Stack."
echo "→ Review and adjust if detection is incomplete; existing stack notes were preserved."
echo ""
echo "Next: bash scripts/snapshot.sh init-stack-probe"
