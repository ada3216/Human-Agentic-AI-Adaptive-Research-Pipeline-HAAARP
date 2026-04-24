---
name: set-model
agent: mag-business
---
Configure which AI model handles which role. Updates custom_models in PROJECT_CONFIG.md.
Valid roles: planner, executor, reviewer.

Usage: /set-model [role] [model-name]
  Example: /set-model reviewer claude-opus-4-6
  Example: /set-model executor gpt-4o

If an argument is provided:
  Update the matching role line in PROJECT_CONFIG.md custom_models section.
  Append to decisions.md: DATE: [today] | MODEL_CONFIG | [role]: [model-name]
  Confirm back: "[role] set to [model-name]"

If no argument:
  Show the current custom_models block from PROJECT_CONFIG.md.

If role is invalid:
  List valid roles and their current values.

## WORKFLOW-END COMMIT (mandatory if this command edits governed files)

Before returning control, run this sequence:
1. `bash scripts/check.sh` — must exit 0 before proceeding
2. Stage only files this command wrote — use `git add <file>...`. Do NOT use `git add -A`.
3. `git status` — confirm what is staged matches the files this command wrote
4. `git commit -m "[type]([scope]): [description]"` to produce a clean git commit
5. `git status --porcelain` — if any listed files were written by this command, stop and fix. Unrelated dirty files are advisory only.
