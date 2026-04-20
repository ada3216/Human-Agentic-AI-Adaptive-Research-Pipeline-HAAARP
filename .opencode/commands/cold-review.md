---
name: cold-review
agent: reviewer
---
Review the provided file path or diff WITHOUT any session implementation context.
Approach the code as if seeing it for the first time.

Read .ai-layer/ARCHITECTURE.md for the project's intended patterns and constraints.

Rate on four dimensions:
  ARCHITECTURE FIT: [STRONG | ACCEPTABLE | WEAK | FAIL]
    Does the code respect the patterns in ARCHITECTURE.md?
  SECURITY POSTURE: [STRONG | ACCEPTABLE | WEAK | FAIL]
    Credential handling, data exposure risks, injection vectors?
  READABILITY: [STRONG | ACCEPTABLE | WEAK | FAIL]
    Can a non-specialist read and understand this code?
  SENSITIVE DATA: [CLEAN | ADVISORY | FAIL]
    Any PII, credentials, or sensitive values handled incorrectly?

List specific findings under each dimension. FAIL items first, then WEAK, then ADVISORY.
End with: OVERALL: [PASS | ADVISORY | FAIL] — one sentence.
