---
name: probe
agent: executor
---
Detect the active model's verbosity and write compensating constraints to PROJECT_CONFIG.md.

Steps:
1. Generate a 3-sentence technical explanation of what a linter does.
2. Assess: if the response is significantly longer than 3 sentences or contains
   preamble, hedging, or pleasantries — classify verbosity=high. Otherwise verbosity=normal.
3. Write to .ai-layer/PROJECT_CONFIG.md section "## Runtime Model Behaviour":

   If verbosity=high:
     verbosity: high
     compensating_constraints: Omit pleasantries, preamble, hedging in all narrative prose.
       State findings directly. Stop. Structured tokens, code blocks, and file content are exempt.

   If verbosity=normal:
     verbosity: normal
     compensating_constraints: none

4. Output one line: probed — verbosity=[high|normal], constraints=[written|none]
5. Surface advisory: "NOTE: /probe writes to PROJECT_CONFIG.md, which OpenCode loads as session instructions at session start. Changes from this probe take effect in the next session, not this one."
