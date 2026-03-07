---
name: agent-creation
description: Creates and maintains AGENTS.md / CLAUDE.md files. Use when creating a new agent context file, auditing an existing one, or after a model failure that revealed a missing constraint. Enforces strict inclusion — rejects more than it accepts.
---

# Agent Creation Agent

## What this is for

The model will fail in this project. It already has, or it will. This file exists to compress those failures into constraints so they don't repeat.

That's the only purpose. Not documentation. Not onboarding. Not completeness. A record of what this model gets wrong here, in this codebase, under real conditions.

---

## Constraint priority (this changes how the model behaves)

Constraints compete for the model's attention. A flat list of ten equally-weighted rules produces weaker adherence than three clearly ranked ones. Every constraint must be assigned a priority, and the file must never have more than two or three at the top level.

**CRITICAL** — violation causes data loss, security breach, irreversible damage, or broken production systems. The model must treat these as hard stops.

**REQUIRED** — violation causes meaningful failure: wrong output, wasted work, broken behaviour that isn't immediately obvious. These are the core of the file.

**AVOID** — violation causes degraded quality or added friction, but is recoverable. Use sparingly. If something only belongs here, question whether it belongs at all.

If everything is CRITICAL, nothing is. Assign honestly.

---

## The inclusion test

Every candidate must pass all three:

1. **Non-inferable** — not derivable from reading the code, file structure, or standard practice
2. **Failure-critical** — if missing, the model makes a real mistake, not just a stylistic one
3. **Current** — still true, still enforced, still relevant to this project as it exists now

When uncertain → reject. Uncertainty means the constraint isn't sharp enough to be useful.

---

## What belongs

- Constraints derived from actual model failures in this project (highest signal)
- Invisible invariants — things that look wrong but are intentional, silent failure modes, undocumented system behaviours
- Hard limits on irreversible actions
- Non-obvious internal APIs or conventions not visible from public docs

## What never belongs

Best practices. Folder descriptions. Style preferences covered by a linter. Generic workflow advice. Anything the model already does reliably. Anything added "just in case."

---

## Format

```
[PRIORITY] [Rule in one sentence] — [what breaks if ignored]
```

Examples:
- `CRITICAL: Never run migrations outside the deploy script — ORM state and DB state decouple silently, no error is thrown`
- `REQUIRED: The /legacy/auth route is still called by iOS v2 clients — do not remove or modify it`
- `AVOID: Don't use session.query() in this service — the wrapper in db/session.py handles retry logic session.query() bypasses`

Size limit: 3–7 constraints. If you have more, you're adding noise — go back and apply the test harder. A short file with high adherence beats a complete file the model skims.

---

## The failure loop

When a failure occurs:

1. What went wrong?
2. Was a constraint missing? → Add it at the appropriate priority
3. Was a constraint present but ignored or misapplied? → Rewrite or delete it — repeating it louder doesn't work
4. Was a constraint present but wrong? → Fix or remove it

New constraints come from real failures, not from anticipating hypothetical ones. A constraint you've never needed is a constraint that's diluting the ones you do.

---

## Audit triggers (specific, not vague)

Run the audit after:
- Any model error or unexpected output
- Every PR or significant task completion
- Any architectural change to the codebase
- When the file hasn't been touched in 20+ sessions

For every existing constraint, reapply the three-part test. Then apply one more: *has this constraint actually prevented a failure, or has it just sat there?* If it hasn't been exercised — delete it unless the protected failure would be catastrophic.

Audit output format:

```
REMOVED: "[constraint]" — [now inferable / stale / never triggered / diluting higher-priority items]
KEPT: "[constraint]" — [last failure it prevented: date/task]
ADDED: "[constraint]" — [PRIORITY] from failure on [date/task]: [what went wrong]
```

Present this to the user before applying. Default toward deletion when uncertain.

---

## Self-maintenance instruction (embed in every file you create)

```
## Maintenance
Update this file when the model fails, not on a schedule.
New constraints come from real failures only.
If a constraint hasn't prevented a failure and isn't protecting against catastrophe — delete it.
When uncertain: delete. Silence is better than noise that dilutes what matters.
```
