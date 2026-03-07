---
name: skill-creation
description: Creates and maintains SKILL.md files for Claude Code / Claude.ai skill systems. Use when capturing a workflow into a reusable skill, auditing existing skills for bloat or dead triggers, or deciding whether something should be a skill vs an agent constraint. Distinct from agent-creation — skills are on-demand, agent files are always-loaded.
---

# Skill Creation Agent

## The structural advantage

Skills cost zero tokens when not in use. This is the only reason to prefer them over agent constraints. A skill loads only when triggered, so it can be detailed and specific without permanently occupying context. Use this.

---

## The only reason to create a skill

The model handles this task type worse without the skill — consistently enough that it's worth maintaining the skill.

"Consistently enough" doesn't require perfect repeatability. Probabilistic failure counts: if the model gets this right 60% of the time without the skill and 90% with it, that's a valid skill. What doesn't count: a single failure, marginal stylistic improvement, or covering for a task type the model handles adequately.

The practical test: remove the skill and run the task. Is the output meaningfully worse? If not, delete it.

---

## Three checks before creating

1. **Non-inferable** — contains knowledge or procedure the model can't reliably reproduce from training alone
2. **Reusable** — this task type recurs enough to justify maintaining the skill
3. **Triggerable** — specific, identifiable conditions activate it — not "when helpful"

All three must be true. If any fails → don't create it.

---

## The description is the whole game

The description is the only thing read before deciding to load the skill. Vague → never triggers. Too broad → triggers incorrectly. Both are failures.

A good description answers in ~50 words:
- What capability does this provide?
- What specific conditions activate it (including implicit phrasings)?
- What goes wrong without it?

**Weak:** `Creates spreadsheets from data.`

**Strong:** `Creates production-quality .xlsx files with correct formatting, formulas, and data types. Use when the user needs an actual Excel file — even if they say "spreadsheet", "table", or "export to Excel". Without this skill, output commonly has incorrect cell types, missing data validation, or broken formula references.`

The strong version names failure modes, handles implicit triggers, and gives a decision rule. Write every description this way.

Test the description before the body. If the skill doesn't trigger reliably, fix the description first — the body is irrelevant if the skill never loads.

---

## Structure

```
SKILL.md           ← trigger description + core workflow only (<300 lines)
references/        ← deep docs, loaded on demand with explicit pointers
scripts/           ← deterministic sub-tasks
assets/            ← templates, static files
```

Only non-obvious steps belong in SKILL.md. If the model would do it anyway, cut it. Use reference files to keep the main file lean — and when referencing, be explicit about when to load: "If the user needs X, read `references/x.md` before step 3."

---

## SKILL.md body format

```markdown
## What this prevents
[The specific failure mode. One or two sentences.]

## When to use this vs [closest alternative]
[Only if meaningful overlap exists. A real decision rule, not a vague distinction.]

## Workflow
[Numbered steps. Imperative. Non-obvious only.]

## Critical details
[The things the model gets wrong without this. The actual reason the skill exists.]

## Output check
[How to verify correctness before presenting to the user.]
```

Omit sections with nothing to say. An empty section is worse than no section.

---

## Trigger testing

Before shipping, test against:
- 3–5 prompts that **should** trigger (include implicit phrasings — users often describe the need without naming the format)
- 3–5 near-misses that **should not** (same domain, different need — easy negatives test nothing)

Trigger fails → fix description.
Output fails → fix body.
These are different problems.

---

## Maintenance

A skill that doesn't trigger in real usage → delete it.
A skill whose output is indistinguishable from unassisted output → delete it.
A skill over ~300 lines → split or prune it.

No archiving. No "keeping it just in case." Unused skills consume maintenance attention and can produce false triggers. Delete them.

---

## Agent constraint vs skill — the decision

| | Agent constraint | Skill |
|---|---|---|
| Loaded | Always, every task | Only when triggered |
| Use for | Project-wide invariants | Specific task types |
| Failure mode | Context bloat, diluted adherence | Under/over-triggering |
| Create when | Model fails consistently on project-specific constraint | Model fails consistently on a specific task type |

If a skill triggers on nearly every task → move it to the agent file.
If an agent constraint only matters for specific task types → convert it to a skill.
