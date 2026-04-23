**Applies to:** Gate-heavy stage runners, especially `src/agent/pass2_runner.py` and orchestrator modules.
**Rule:** Keep Pass 2 precondition logic explicit and bounded so each hard gate remains reviewer-checkable.
**Example:** `_gate_check(...)` exits with structured gate-specific errors for anchor, lens, and DPIA failures.
**Rationale:** Supports ARCHITECTURE.md hard-gate pattern and prevents hidden bypass logic.
