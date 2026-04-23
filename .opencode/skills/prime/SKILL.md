# Prime Skill

## Purpose

Produce a complete working context block at session start.
Read three sources and nothing else. Output one block and stop.

## Sources (read in this order)

1. `bash scripts/state.sh show`
2. `tail -20 .ai-layer/decisions.md`
3. MCP query: `mcp_memory_search_nodes` with query `"last_task architectural_decision constraint"`
4. Apply provenance filter: only trust memory entries containing the current `project_name` (from `PROJECT_CONFIG.md`) as an observation.

Memory provenance filter (applies to all returned nodes):
- If a node has no "project:" observation: log to session-toollog.md:
  "MEMORY_IGNORED | [node-name] | reason: no project field" — do not surface.
- If a node's "project:" value does not match the current project name
  (from PROJECT_CONFIG.md): log "MEMORY_IGNORED | [node-name] | reason: project mismatch"
  — do not surface.
- If a node has no "date:" observation and entity type is architectural_decision
  or constraint: log "MEMORY_IGNORED | [node-name] | reason: no date field" — do not surface.
- If a node's "date:" is more than 90 days ago: surface it with a prefix note:
  "⚠️ Stale constraint (date: [date]) — verify still applies before acting on it."

This filter applies to all memory reads in normal operation.

## Output — produce this block exactly

Fill in all bracketed values from the sources above:

```
PRIME CONTEXT
State: phase=[phase] | autonomy=[autonomy] | slot=[implement_slot] | pending_review=[pending_review]
Last task: [current_task or last_completed_phase, whichever is non-null, else "none"]
Recent decisions:
  [most recent decisions.md entry, one line]
  [second most recent]
  [third most recent]
Active constraints: [memory entities tagged constraint or architectural_decision, max 5, one per line, else "none"]
```

If `pending_review=true` — append immediately after the block:
```
ACTION REQUIRED: REVIEW_STOP pending. Switch to a different AI provider before running /review.
```

If `design_stop_pending=true` — append:
```
ACTION REQUIRED: DESIGN_STOP pending: [design_stop_question]
```

## What NOT to do

Do not add narrative. Do not query memory for any tag other than the three above.
Do not read any file other than state.json and decisions.md.
The PRIME CONTEXT block is the complete output. Stop.

## Memory write at implement_complete

When invoked by the executor after task completion:
1. Call `mcp_memory_delete_entities` to delete any existing entity named `last_task`
2. Call `mcp_memory_create_entities`:
   - name: `last_task`
   - entityType: `task`
   - observations: `["task: [current_task]", "outcome: COMPLETE", "date: [ISO date]", "project: [project_name from PROJECT_CONFIG.md]"]`
