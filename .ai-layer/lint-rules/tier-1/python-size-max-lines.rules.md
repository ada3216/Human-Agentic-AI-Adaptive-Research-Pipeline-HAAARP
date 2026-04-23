**Applies to:** Python files under `src/` and `tests/`.
**Rule:** Maintain reviewable module/function size in line with `PROJECT_CONFIG.md` limits (`max_file_lines: 300`, `max_function_lines: 50`).
**Example:** Split oversized modules/functions rather than extending monolithic stage handlers.
**Rationale:** Keeps sensitive-governance logic inspectable and within enforced project constraints.
