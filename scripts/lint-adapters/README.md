# Lint Adapters

Each `.sh` file is a self-contained adapter for one language.
`scripts/project-init.sh` detects which apply and generates `scripts/lint-check.sh`.

Interface every adapter must satisfy:
- Takes no arguments
- Reads rule files from `.ai-layer/lint-rules/tier-1/`
- Exits 0 on pass, non-zero on fail
- Prints violations to stdout

Adding a new language:
1. Create `scripts/lint-adapters/<language>.sh`
2. Follow the interface above
3. Run `/project-init` — it regenerates `lint-check.sh` automatically

No other file changes are needed to add a language.

Included: js-ts.sh, python.sh, shell.sh

Naming conventions (required by section 3.8):
- Use `eslint` naming for JS/TS adapter rule files (`*.eslint.json`)
- Use `ruff` naming for Python adapter rule files (`*.ruff.toml`)
- Use `pycheck` naming for repo-specific Python structural checks (`*.pycheck.json`)
- Every rule file must have a matching `*.rules.md` explanation file
