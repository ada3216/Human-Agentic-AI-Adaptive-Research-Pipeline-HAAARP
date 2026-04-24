**Applies to:** All `.py` files in `src/` and `tests/`

**Rule:** Follow PEP 8 naming conventions: `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for module-level constants. Test functions follow `test_[module]_[condition]_[expected_outcome]`.

**Example:**
```python
# CORRECT
def check_sensitivity(self, sensitivity: str) -> None: ...
class Orchestrator: ...
ERROR_CODES = {...}

# WRONG
def CheckSensitivity(s): ...
```

**Rationale:** Factory category: grep-ability. Dominant convention observed in all `src/` modules (orchestrator.py, grounding_checker.py, etc.). Consistent naming enables codebase search and review.
