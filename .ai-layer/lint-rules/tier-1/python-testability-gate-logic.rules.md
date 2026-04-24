**Applies to:** All `tests/test_*.py` files

**Rule:** All tests run with `MOCK_LLM=true`. Tests must exercise actual gate logic — do not mock the gate checks themselves. Every new module must have at least one failure-path test and one success-path test. Do not use `pytest.skip()` or `@pytest.mark.skip` on governance tests.

**Example:**
```python
# CORRECT — exercises actual gate logic
def test_pass2_rejects_local_anchor(valid_anchor, tmp_artifacts):
    valid_anchor["anchor_type"] = "local"
    # ... assert sys.exit(3) is called

# WRONG — mocks the check itself
@patch("agent.pass2_runner.check_anchor_type")
def test_pass2_anchor(mock_check): ...
```

**Rationale:** Factory category: testability. GUARDRAILS.md §5; COPILOT_INSTRUCTIONS.md §Testing. Gate bypass in tests would mask governance regressions.
