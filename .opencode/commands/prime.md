---
name: prime
agent: executor
---
Invoke the prime skill at .opencode/skills/prime/SKILL.md.

Read:
   bash scripts/state.sh show
   tail -20 .ai-layer/decisions.md
   mcp_memory_search_nodes with query: "last_task architectural_decision constraint"

Produce the PRIME CONTEXT block exactly as specified in the skill.
If ACTION REQUIRED lines apply, surface them above the context block.
Output nothing else.
