Plan: Fix lint layer — Makefile target, mismatched ruff rules, glob-ability artifact containment rule
Scope: CONTAINED
Risk: LOW
Date: 2026-04-23
Target surface: FRAMEWORK

---

## Context sources used

- `Makefile` (lines 11-12 — current broken `lint` target)
- `scripts/lint-check.sh` (authoritative lint entry point)
- `scripts/lint-adapters/python.sh` (concat-based ruff config merge mechanism)
- `scripts/lint-adapters/README.md` (naming and interface conventions)
- `.ai-layer/lint-rules/tier-1/*.ruff.toml` (all 7 existing ruff configs)
- `.ai-layer/lint-rules/tier-1/*.rules.md` (stated intent for each rule)
- `.ai-layer/PROJECT_CONFIG.md` (`max_file_lines: 300`, `max_function_lines: 50`)
- `.ai-layer/ARCHITECTURE.md` (hard-gate patterns, prohibited integrations)

---

## Architectural constraints this plan operates within

- `scripts/lint-adapters/python.sh` **concatenates** all `*.ruff.toml` files into one merged config using shell `cat`. This means **duplicate TOML table headers** (e.g., two `[lint]` sections) will cause a TOML parse error. Each ruff rule file must use a **unique subtable** header.
- The `select` / `extend-select` top-level ruff keys cannot be safely distributed across multiple concatenated files (last-one-wins and duplicate-key conflict). Rule activation via `select` must live in `python.sh` or the caller, not in individual rule files.
- Artifact write containment (files outside `src/modules/` and `src/tools/` writing to `artifacts/`) **cannot** be enforced by ruff, which operates on imports and AST nodes, not on runtime path strings in function arguments.
- Every `.ruff.toml` must have a matching `.rules.md` (per `README.md` §3.8).

---

## Design decisions resolved

None — all three issues have clear resolutions from direct file evidence.

---

## Why this approach

Issue 1 is a one-line Makefile fix: the lint target hard-codes `flake8` (not installed) while `scripts/lint-check.sh` is the authoritative entry point already referenced in CI. Routing through the script is correct.

For the six mismatched ruff configs: the concat-merge architecture means each file must own a unique TOML subtable. Where ruff can partially enforce the stated intent via a subtable option (complexity limit, pycodestyle doc length, flake8-errmsg plugin config, pytest-style options), we use valid config. Where ruff has no subtable mechanism for the intent (module boundary enforcement, naming pattern checks), we replace the wrong config with RUFF-LIMITATION comments and a CI-ALTERNATIVE grep to make the gap explicit and actionable.

For the new artifact-containment rule: ruff's `banned-api` operates on import names and attribute chains, not on string literals passed to `open()` or `Path()`. The rule cannot be enforced by ruff statically. A grep-based CI check against `artifacts/` path strings in files outside the allowed directories is the correct mechanism. The ruff.toml file documents this clearly.

---

## What is being removed

- `[lint.flake8-annotations]` block from `python-boundaries-human-verdict-cli-only.ruff.toml` (wrong — annotation suppression; unrelated to verdict boundary)
- `[lint.mccabe] max-complexity = 20` from `python-boundaries-pass2-gate-checks.ruff.toml` (replaced with `max-complexity = 8`)
- `[lint.isort]` block from `python-grep-ability-artifact-name-patterns.ruff.toml` (unrelated to naming patterns)
- Empty `[lint.flake8-errmsg]` block from `python-safety-structured-error-codes.ruff.toml` (replaced with configured block)
- `[lint.pydocstyle]` block from `python-size-max-lines.ruff.toml` (docstyle unrelated to size limits; replaced with `[lint.pycodestyle]`)
- Empty `[lint.flake8-pytest-style]` block from `python-testability-governance-test-naming.ruff.toml` (replaced with meaningful options)

---

## Implementation steps

### Step 1 — Fix `Makefile` lint target

**File:** `Makefile`
**Line 12:** Replace `flake8 src/ tests/ --max-line-length=100 --ignore=E501,W503`
**With:** `bash scripts/lint-check.sh`

Result:
```makefile
lint:
	bash scripts/lint-check.sh
```

---

### Step 2 — Fix `python-boundaries-human-verdict-cli-only.ruff.toml`

**File:** `.ai-layer/lint-rules/tier-1/python-boundaries-human-verdict-cli-only.ruff.toml`

Replace entire file content with:

```toml
# RUFF-LIMITATION: Ruff cannot enforce that only src/tools/review_cli.py writes
# non-null values to the `human_verdict` field. This boundary requires cross-file
# dataflow analysis (which module assigns which dict key) — outside ruff's scope.
#
# CI-ALTERNATIVE: Add to .github/workflows/ci.yml —
#   grep -rn "human_verdict" src/ \
#     | grep -v "src/tools/review_cli.py" \
#     | grep -vE '(null|None|#)' \
#     && echo "VIOLATION: human_verdict written outside review_cli.py" && exit 1 || true
```

The `.rules.md` for this file already accurately describes the intent — no change needed.

---

### Step 3 — Fix `python-boundaries-pass2-gate-checks.ruff.toml`

**File:** `.ai-layer/lint-rules/tier-1/python-boundaries-pass2-gate-checks.ruff.toml`

Replace entire file content with:

```toml
# Partial enforcement: McCabe complexity limit of 8 keeps gate-check functions
# bounded and reviewer-inspectable, directly supporting the ARCHITECTURE.md
# hard-gate pattern that requires each gate to be explicitly coded.
# Lower than ruff's default of 10 to enforce "simple and legible" gate logic.
#
# RUFF-LIMITATION: Ruff cannot verify that Pass 2 entry points actually call
# all required prerequisite checks (anchor hash, lens lock, DPIA existence).
# That requires integration/contract testing.
#
# CI-ALTERNATIVE: Add to .github/workflows/ci.yml —
#   MOCK_LLM=true pytest tests/ -k "pass2" -v
#   (ensures gate tests run in CI and prerequisite checks are covered)

[lint.mccabe]
max-complexity = 8
```

The `.rules.md` for this file already accurately describes the intent — no change needed.

---

### Step 4 — Fix `python-grep-ability-artifact-name-patterns.ruff.toml`

**File:** `.ai-layer/lint-rules/tier-1/python-grep-ability-artifact-name-patterns.ruff.toml`

Replace entire file content with:

```toml
# RUFF-LIMITATION: Ruff cannot enforce that artifact output filenames follow
# governance naming conventions (pass1_output_*, pass1_anchor_*, pass2_output_*,
# evidence_review_*, audit_bundle_*). This requires checking string literals at
# Path/open call sites — outside ruff's static analysis scope.
#
# CI-ALTERNATIVE: Add to .github/workflows/ci.yml —
#   grep -rn "artifacts/" src/ \
#     | grep -vE "(pass1_output_|pass1_anchor_|pass2_output_|evidence_review_|audit_bundle_)" \
#     | grep -vE "(#|\.rules\.md)" \
#     && echo "VIOLATION: artifact path does not match governance naming pattern" && exit 1 || true
```

The `.rules.md` for this file already accurately describes the intent — no change needed.

---

### Step 5 — Fix `python-safety-structured-error-codes.ruff.toml` + update `python.sh`

**File:** `.ai-layer/lint-rules/tier-1/python-safety-structured-error-codes.ruff.toml`

Replace entire file content with:

```toml
# Partial enforcement: max-string-length = 0 configures the flake8-errmsg plugin
# to flag all bare string literals in raise statements (EM101/EM102/EM103).
# EM rules are activated via extend-select in scripts/lint-adapters/python.sh.
#
# RUFF-LIMITATION: Ruff cannot verify that error variable values match registered
# codes in docs/error_codes.md (e.g., ERR_DPIA_MISSING, ERR_ANCHOR_HASH_MISMATCH).
# Code registry compliance requires a grep or custom script.
#
# CI-ALTERNATIVE: Add to .github/workflows/ci.yml —
#   grep -rn 'raise.*Error(' src/ \
#     | grep -vE 'ERR_[A-Z_]+' \
#     && echo "VIOLATION: raise without structured ERR_ code" && exit 1 || true

[lint.flake8-errmsg]
max-string-length = 0
```

**Also update** `scripts/lint-adapters/python.sh` line 12.

Current line 12:
```
{ echo "line-length = 120"; echo "";
```

Replace with:
```
{ echo "line-length = 120"; echo 'extend-select = ["EM101", "EM102", "EM103"]'; echo "";
```

This emits `extend-select` at the top of the merged config, before any `[lint.*]` subtable headers, so it is valid TOML and does not conflict with subtable keys in the individual rule files.

---

### Step 6 — Fix `python-size-max-lines.ruff.toml`

**File:** `.ai-layer/lint-rules/tier-1/python-size-max-lines.ruff.toml`

Replace entire file content with:

```toml
# Partial enforcement: max-doc-length = 120 flags docstrings and comments
# exceeding the project line-length limit. Code line length is governed by
# the root `line-length = 120` setting emitted by python.sh.
#
# RUFF-LIMITATION: Ruff cannot enforce max file length (PROJECT_CONFIG.md:
# max_file_lines = 300) or max function length (max_function_lines = 50).
# File and function line counts require a separate script or CI check.
#
# CI-ALTERNATIVE: Add to .github/workflows/ci.yml —
#   python - <<'EOF'
#   import sys, pathlib
#   violations = []
#   for f in pathlib.Path("src").rglob("*.py"):
#       lines = f.read_text().splitlines()
#       if len(lines) > 300:
#           violations.append(f"{f}: {len(lines)} lines (max 300)")
#   if violations:
#       print("\n".join(violations)); sys.exit(1)
#   EOF

[lint.pycodestyle]
max-doc-length = 120
```

The `.rules.md` for this file already accurately describes the intent — no change needed.

---

### Step 7 — Fix `python-testability-governance-test-naming.ruff.toml`

**File:** `.ai-layer/lint-rules/tier-1/python-testability-governance-test-naming.ruff.toml`

Replace entire file content with:

```toml
# Partial enforcement: flake8-pytest-style options enforce fixture and raises
# conventions in tests, keeping test structure consistent and governance-legible.
# fixture-parentheses = false enforces @pytest.fixture (not @pytest.fixture())
# raises-require-match-for flags bare pytest.raises(ExcType) without match=
#
# RUFF-LIMITATION: Ruff cannot enforce test function naming conventions
# (e.g., test_pass2_refuses_when_<condition>, test_review_cli_rejects_<condition>).
# Name pattern enforcement requires a grep check.
#
# CI-ALTERNATIVE: Add to .github/workflows/ci.yml —
#   grep -rn "^def test_" tests/ \
#     | grep -vE "test_(pass[12]|review_cli|audit|lens|anchor|dpia|strand|gate)" \
#     && echo "WARNING: test name may not encode governance behavior" || true

[lint.flake8-pytest-style]
fixture-parentheses = false
raises-require-match-for = ["Exception", "RuntimeError", "ValueError", "SystemExit"]
```

The `.rules.md` for this file already accurately describes the intent — no change needed.

---

### Step 8 — Create `python-glob-ability-artifact-containment.ruff.toml` (new file)

**File:** `.ai-layer/lint-rules/tier-1/python-glob-ability-artifact-containment.ruff.toml`

Content:

```toml
# RUFF-LIMITATION: Ruff's banned-api operates on import names and attribute chains,
# not on string literals passed to open(), pathlib.Path(), or json.dump() calls.
# It cannot enforce that only src/modules/ and src/tools/ write to paths matching
# "artifacts/". This boundary requires checking the content of string arguments
# at call sites — outside ruff's static analysis scope.
#
# CI-ALTERNATIVE: Add to .github/workflows/ci.yml —
#   grep -rn '"artifacts/' src/ tests/ \
#     | grep -vE "^(src/modules/|src/tools/)" \
#     | grep -v "#" \
#     && echo "VIOLATION: artifacts/ path referenced outside src/modules/ or src/tools/" && exit 1 || true
#
#   grep -rn "'artifacts/" src/ tests/ \
#     | grep -vE "^(src/modules/|src/tools/)" \
#     | grep -v "#" \
#     && echo "VIOLATION: artifacts/ path referenced outside src/modules/ or src/tools/" && exit 1 || true
```

---

### Step 9 — Create `python-glob-ability-artifact-containment.rules.md` (new file)

**File:** `.ai-layer/lint-rules/tier-1/python-glob-ability-artifact-containment.rules.md`

Content:

```markdown
**Applies to:** All Python files under `src/` and `tests/`.
**Rule:** Only `src/modules/` and `src/tools/` may write to paths under `artifacts/`. No other Python file should construct or resolve paths into the `artifacts/` directory.
**Example:** `src/modules/pass1_runner.py` writing `artifacts/pass1_output_seed42.json` is permitted; `src/agent/orchestrator.py` directly writing to `artifacts/` is a violation.
**Rationale:** Artifact write containment prevents uncontrolled side-effects in governed output directories, preserves the append-only and hash-tracked artifact lifecycle, and keeps the audit trail predictable.

## What ruff can enforce

Nothing directly. Ruff's `flake8-tidy-imports.banned-api` operates on import names and module attribute paths, not on runtime string literals passed to I/O calls.

## Recommended CI enforcement

Add two grep checks to `.github/workflows/ci.yml` (one for double-quote, one for single-quote artifact path references) that fail if any file outside `src/modules/` or `src/tools/` references an `artifacts/` path string. See the `# CI-ALTERNATIVE:` comments in the companion `.ruff.toml` for exact grep commands.
```

---

## Acceptance criteria

- `make lint` runs `bash scripts/lint-check.sh` (not `flake8`); verify: `grep -A1 '^lint:' Makefile` shows `bash scripts/lint-check.sh`.
- No two `.ruff.toml` files in tier-1 share an identical TOML table header; verify: `grep -h '^\[' .ai-layer/lint-rules/tier-1/*.ruff.toml | sort | uniq -d` returns empty.
- Every `.ruff.toml` in tier-1 has a corresponding `.rules.md`; verify: `for f in .ai-layer/lint-rules/tier-1/*.ruff.toml; do [ -f "${f%.ruff.toml}.rules.md" ] || echo "MISSING: $f"; done` returns empty.
- `python-glob-ability-artifact-containment.ruff.toml` and `python-glob-ability-artifact-containment.rules.md` both exist; verify: `ls .ai-layer/lint-rules/tier-1/python-glob-ability-artifact-containment.*`
- `python-safety-structured-error-codes.ruff.toml` contains `max-string-length = 0` under `[lint.flake8-errmsg]`.
- `python-testability-governance-test-naming.ruff.toml` contains `fixture-parentheses` and `raises-require-match-for` under `[lint.flake8-pytest-style]`.
- `python-size-max-lines.ruff.toml` uses `[lint.pycodestyle]` not `[lint.pydocstyle]`.
- `python-boundaries-pass2-gate-checks.ruff.toml` contains `max-complexity = 8`.
- `scripts/lint-adapters/python.sh` emits `extend-select = ["EM101", "EM102", "EM103"]` in the merged config header.
- `python-boundaries-no-cloud-llm.ruff.toml` is unchanged (correctly implemented; must not be modified).
- Existing ARCHITECTURE.md hard-gate and local-only constraints are unmodified.
- `bash scripts/lint-adapters/python.sh` exits 0 (or SKIP if ruff not installed) with no TOML parse errors.

---

## Notes

- `python-boundaries-no-cloud-llm.ruff.toml` is the one correctly implemented ruff config in tier-1. It must not be touched.
- The CI-ALTERNATIVE grep commands in each file are informational/advisory — they are not wired into `.github/workflows/ci.yml` by this plan. A follow-on task should implement them.
- The concat-merge design in `python.sh` requires `extend-select` to appear before any `[section]` header in the merged output. Step 5 ensures this by emitting it on line 2 of the merged config.

---

─────────────────────────────────────────
NEXT STEP
Command:  /review-plan
Model:    Switch to a DIFFERENT AI provider before running /review-plan
Action:   Open a new session on a different provider, then run /review-plan
─────────────────────────────────────────
