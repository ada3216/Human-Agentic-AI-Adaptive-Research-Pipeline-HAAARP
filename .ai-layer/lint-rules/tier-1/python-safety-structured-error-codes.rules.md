**Applies to:** Python runtime/error-handling paths in `src/`.
**Rule:** Emit structured, actionable errors aligned to `docs/error_codes.md` for governance blocks and sequencing failures.
**Example:** `[ERR_DPIA_MISSING] ...` plus `Action: ...` then deterministic exit code.
**Rationale:** Keeps safety-critical failures auditable and consistent with governance docs and tests.
