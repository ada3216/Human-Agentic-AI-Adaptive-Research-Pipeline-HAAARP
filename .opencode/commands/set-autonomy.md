---
name: set-autonomy
agent: mag
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
If this command edits governed files directly, end with a clean git commit before exit.
