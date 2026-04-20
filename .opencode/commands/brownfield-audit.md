---
name: brownfield-audit
agent: reviewer
---
Audit an existing codebase for Magentica 2.0 governance readiness.
Do NOT fix anything. Produce a report only.

Read PROJECT_CONFIG.md for max_file_lines and max_function_lines thresholds.

Scan and report on four areas:

1. FILE SIZE VIOLATIONS
   Run: find . -name "*.ts" -o -name "*.js" -o -name "*.py" | xargs wc -l 2>/dev/null | sort -rn | head -20
   List files over max_file_lines with their line counts.

2. SENSITIVE DATA RISKS
   Scan for: credential patterns (API keys, passwords hardcoded in source),
   sensitive data written outside a /workspace or Docker context, PII in committed files.
   Report findings with file and approximate line.

3. MAGENTICA 2.0 INFRASTRUCTURE
   state.json: exists? schema_version=1?
   decisions.md: exists? has INIT entry?
   lint-check.sh: exists? (if not, /project-init not yet run)
   gatekeeper.js: compiled and present?

4. LANGUAGE COVERAGE
   Languages present in codebase vs adapters available in scripts/lint-adapters/.
   Note any language with no matching adapter.

Produce output in this exact format:

BROWNFIELD AUDIT REPORT
Date: [ISO date]

BLOCKERS (must fix before Magentica can govern this project):
  [numbered list or "None"]

RECOMMENDATIONS (should fix, not blocking):
  [numbered list or "None"]

ALREADY COMPLIANT:
  [bullet list or "Nothing checked yet"]

NEXT STEP: [single most important action for the human to take]
