# Lint Rules

Rules in `tier-1/` are active on every lint run.
They are the executable architectural specification for this project.
When lint passes, code conforms to the project's stated intentions.
When lint fails, code has drifted from a stated architectural intention.

## File naming

| Extension | Adapter | Notes |
|---|---|---|
| `*.eslint.json` | js-ts.sh | Merged into ESLint config at lint time |
| `*.ruff.toml` | python.sh | Merged into Ruff config at lint time |
| `*.rules.md` | Human-readable | Required for every rule — states the intention |

Every rule file MUST have a matching `.rules.md` explaining why the rule exists.
A lint rule that cannot be connected to a stated intention is not a lint rule — it is noise.

## Adding rules

Rules are added only via `/project-init` or an explicit plan with DESIGN_STOP confirmation.
Rules are never added automatically.

## Configurable thresholds (from PROJECT_CONFIG.md)

- `max_file_lines: 300`
- `max_function_lines: 50`
