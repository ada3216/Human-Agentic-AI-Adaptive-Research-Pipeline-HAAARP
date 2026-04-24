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

## WORKFLOW-END COMMIT (mandatory after governed-file edits)

Before returning control, run this sequence:
1. `bash scripts/check.sh` — must exit 0 before proceeding
2. Stage only files this command wrote — use `git add <file>...`. Do NOT use `git add -A`.
3. `git status` — confirm what is staged matches the files this command wrote
4. `git commit -m "[type]([scope]): [description]"` to produce a clean git commit
5. `git status --porcelain` — if any listed files were written by this command, stop and fix. Unrelated dirty files are advisory only.
