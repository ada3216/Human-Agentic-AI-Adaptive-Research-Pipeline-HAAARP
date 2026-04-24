---
name: set-autonomy
agent: mag-business
---
Read the argument provided after /set-autonomy.
Valid values: informed-yolo, full-yolo.

If a valid argument is provided:
  Run: bash scripts/set-autonomy.sh [argument]
  If the script exits with an error (non-zero), surface the block message to the user and stop.
  If successful, this updates the autonomy field in state.json.
  Confirm back with a one-line summary of what changes:
    informed-yolo: "Review stops active. /review required on a different AI provider after each /implement."
    full-yolo: "Review stops disabled. DESIGN_STOP still fires for design decisions. Not recommended for sensitive data phases."
  Show the current setting: bash scripts/state.sh get autonomy

If no argument is provided:
  Show the current setting and list valid options.

Invalid argument:
  Show valid options and the current setting. Do not write anything.

## WORKFLOW-END COMMIT (mandatory if this command edits governed files)

Before returning control, run this sequence:
1. `bash scripts/check.sh` — must exit 0 before proceeding
2. Stage only files this command wrote — use `git add <file>...`. Do NOT use `git add -A`.
3. `git status` — confirm what is staged matches the files this command wrote
4. `git commit -m "[type]([scope]): [description]"` to produce a clean git commit
5. `git status --porcelain` — if any listed files were written by this command, stop and fix. Unrelated dirty files are advisory only.
