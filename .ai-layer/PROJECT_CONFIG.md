## Project Context

project_name: magentica-governance-workflow
project_description: Governance-first human–AI workflow with auditable stops and gates
project_type: workflow-governance-tooling
governed_languages: js-ts,python,shell
data_sensitivity: mixed
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

## Runtime Model Behaviour

verbosity: terse
compensating_constraints: none
