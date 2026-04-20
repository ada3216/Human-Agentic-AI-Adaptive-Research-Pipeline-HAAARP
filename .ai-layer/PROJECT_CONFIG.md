# Canonical project initialization configuration for governance and execution defaults.

## Project Context
- project_name: Agentic Human–AI Research Pipeline
- project_description: governance-first local AI-assisted qualitative research pipeline with hard methodological and ethics gates
- project_type: production
- governed_languages: TypeScript, JavaScript, Python, Shell
- project_stage: scaffold-with-core-implementation
- custom_models:
  - planner: unset — update manually
  - executor: unset — update manually
  - reviewer: unset — update manually

## Operational Constraints
- max_file_lines: 300
- max_function_lines: 50

## Runtime Model Behaviour
- compensating_constraints: none

## Data Sensitivity
- data_sensitivity: sensitive
- sensitivity_reason: therapy/health/special-category + DPIA workflow
