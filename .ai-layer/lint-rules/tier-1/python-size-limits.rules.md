**Applies to:** All `.py` files

**Rule:** Maximum 300 lines per file. Maximum 50 lines per function. Values sourced from PROJECT_CONFIG.md (`max_file_lines`, `max_function_lines`). Cohesive atomic units (e.g. `run_pipeline`) may exceed function limit with a local `# EXEMPT:` comment and justification.

**Example:**
```python
# A 45-line function: OK
# A 55-line function without EXEMPT comment: VIOLATION
# A 55-line function with `# EXEMPT: cohesive atomic unit` comment: OK if justified
```

**Rationale:** Factory category: size. PROJECT_CONFIG.md operational constraints. Keeps code human-auditable — a non-specialist should be able to read any function and explain what it does.
