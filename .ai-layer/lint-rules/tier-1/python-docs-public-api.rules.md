**Applies to:** All public functions in `src/`

**Rule:** Every public function must have a docstring with I/O specification (parameters, return type, exit codes if applicable). Module-level docstrings must state purpose, exit codes used, and exception contract.

**Example:**
```python
def check_sensitivity(self, sensitivity: str) -> None:
    """Validate sensitivity value and gate DPIA if special_category.

    Args:
        sensitivity: One of public_text, personal_non_sensitive, special_category.

    Exits:
        ERR_SENSITIVITY_UNKNOWN (code 1) if value is not recognised.
    """
```

**Rationale:** Factory category: docs. GUARDRAILS.md §8 checklist item: "All new public functions have docstrings with I/O specification." Enables audit and supervisor review of pipeline behavior.
