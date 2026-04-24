---
name: cold-review
agent: reviewer
---
Review the provided file path or diff WITHOUT any session implementation context.
Approach the code as if seeing it for the first time.

If the human invokes the command with a persona flag (examples: `--as reliability`, `--as security`, `--as scalability`, `--as frontend`, `--as readability`), apply a focused lens on that dimension before running the four standard dimensions. The focused lens means: weight findings in that dimension more heavily, spend more review attention on it, and flag lower-severity issues in that dimension that would otherwise be ADVISORY as WEAK.

Supported personas and focus areas:
- `reliability` - timeouts, retries, error handling, graceful degradation, circuit breakers
- `security` - credential handling, injection vectors, input validation, output encoding, access control
- `scalability` - unbounded loops, N+1 queries, missing pagination, synchronous blocking in hot paths
- `frontend` - component decomposition, state management, snapshot testability, prop drilling, accessibility
- `readability` - naming, function length, cognitive complexity, inline comments on non-obvious logic

If no persona flag is provided, all four dimensions are weighted equally.

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
End with: OVERALL: [PASS | ADVISORY | FAIL] - one sentence. If a persona was specified, append `(reviewed with [persona] lens)`.

Commit exemption: read-only exempt. This command produces review output only, writes no governed files, and does not need a workflow-end commit or a clean git commit.
