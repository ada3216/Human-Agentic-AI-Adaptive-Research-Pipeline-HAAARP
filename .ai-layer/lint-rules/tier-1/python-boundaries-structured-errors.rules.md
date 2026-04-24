**Applies to:** All `.py` files in `src/`

**Rule:** Never raise bare `Exception("message")`. All errors must use structured codes from `docs/error_codes.md` with the format `[ERROR_CODE] message\nAction: instruction`. Use `pipeline_error()` or `sys.exit(code)` with the correct exit code (0–5).

**Example:**
```python
# CORRECT
pipeline_error("ERR_DPIA_MISSING", "artifacts/dpia_signed.json not found.",
               "Complete DPIA checklist and obtain DPO sign-off.")

# WRONG
raise Exception("DPIA file missing")
```

**Rationale:** ARCHITECTURE.md § Non-negotiable architectural patterns; GUARDRAILS.md §2 Error handling. Structured errors enable CI detection and researcher guidance.
