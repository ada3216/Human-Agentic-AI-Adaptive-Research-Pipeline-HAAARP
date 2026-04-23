## Project Context

project_name: unset
project_description: unset
project_type: unset
governed_languages: unset
data_sensitivity: unset
rotation_policy: recommended
single_provider_mode: false
review_attestation: required
custom_models:
  planner: unset
  executor: unset
  reviewer: unset

## Operational Constraints

max_file_lines: 300
max_function_lines: 50
max_file_lines_overrides:
  .opencode/commands/project-init.md: 500
max_file_lines_exempt_globs:
  - .opencode/commands/**
  - .opencode/agents/**
  - .opencode/skills/**
max_function_lines_exemption_policy: "Cohesive atomic units may exceed max_function_lines when splitting would reduce auditability (for example: a single class body, a long switch/case dispatcher, or a generated config block). Keep exceptions narrow and include a local justification comment near the oversized unit."

## Runtime Model Behaviour

verbosity: unset
compensating_constraints: none
