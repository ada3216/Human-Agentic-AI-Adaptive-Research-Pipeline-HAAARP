**Applies to:** Python evidence-review handling code in `src/modules/` and `src/tools/`.
**Rule:** Treat `human_verdict` as a human-owned field and keep non-null verdict writes confined to `src/tools/review_cli.py`.
**Example:** `grounding_checker.py` creates review records with `"human_verdict": null`; `review_cli.py` sets the final verdict object.
**Rationale:** Enforces ARCHITECTURE.md constraint that AI stages cannot finalize adjudication state.
