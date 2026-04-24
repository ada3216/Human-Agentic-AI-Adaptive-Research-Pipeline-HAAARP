---
name: prime
agent: executor
---
Invoke the prime skill at .opencode/skills/prime/SKILL.md.

Read:
   bash scripts/state.sh show
   tail -20 .ai-layer/decisions.md
   memory_search_nodes with query: "last_task architectural_decision constraint"

Produce the PRIME CONTEXT block exactly as specified in the skill.
If ACTION REQUIRED lines apply, surface them above the context block.
Output nothing else.

Commit exemption: read-only exempt. This command produces context output only, writes no governed files, and does not need a workflow-end commit or a clean git commit.
