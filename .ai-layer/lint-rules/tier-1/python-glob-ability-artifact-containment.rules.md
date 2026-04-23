# Rule: python-glob-ability-artifact-containment

**Category:** glob-ability  
**Governed language:** Python  
**Enforcement level:** Documentation + CI grep (ruff limitation)

## Intent

Enforce that artifact writes (paths matching `artifacts/`) only occur inside `src/modules/` and `src/tools/`. No other module, script, or test fixture should write governed artifacts directly.

## What ruff can enforce

Nothing directly. `flake8-tidy-imports.banned-api` works on import names — it cannot track string literals passed to `open()`, `Path()`, or `json.dump()` at runtime.

## Recommended CI enforcement

Add to `.github/workflows/ci.yml` under the lint job:

```bash
# Double-quoted artifact paths
grep -rn '"artifacts/' src/ tests/ \
  | grep -vE "^(src/modules/|src/tools/)" \
  | grep -v "#" \
  && echo "VIOLATION: artifacts/ written outside allowed modules" && exit 1 || true

# Single-quoted artifact paths
grep -rn "'artifacts/" src/ tests/ \
  | grep -vE "^(src/modules/|src/tools/)" \
  | grep -v "#" \
  && echo "VIOLATION: artifacts/ written outside allowed modules" && exit 1 || true
```

## Grounding

- ARCHITECTURE.md: Artifact conventions section — `artifacts/` is a governed output directory.
- PROJECT_CONFIG.md: `compensating_constraints` — append-only behavior after lock points.
