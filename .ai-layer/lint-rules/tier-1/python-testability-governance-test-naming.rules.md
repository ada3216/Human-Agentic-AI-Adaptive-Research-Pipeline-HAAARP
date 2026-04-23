**Applies to:** `tests/**/*.py` governance and adversarial suites.
**Rule:** Keep pytest-style, behavior-descriptive test names that encode gate or governance behavior being asserted.
**Example:** `test_pass2_refuses_when_pass1_anchor_is_local` and `test_review_cli_rejects_anonymous_reviewer`.
**Rationale:** Preserves executable governance documentation and makes regressions grep-discoverable.
