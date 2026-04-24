**Applies to:** All `.py` files

**Rule:** Source code goes in `src/` (agent, modules, prompts, schemas, tools subdirectories). Tests go in `tests/`. Fixtures go in `tests/fixtures/`. No Python product source files at repo root or in `scripts/`.

**Example:**
```
src/modules/dpia_gate.py      ✓
src/agent/orchestrator.py     ✓
tests/test_pipeline.py        ✓
dpia_gate.py (at root)        ✗
```

**Rationale:** Factory category: glob-ability. ARCHITECTURE.md § Key Components; GUARDRAILS.md §4 file placement. Consistent layout enables automated discovery and CI targeting.
