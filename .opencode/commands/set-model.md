---
name: set-model
agent: mag
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
