---
name: project-init
agent: planner
---
1. Run: bash scripts/project-init.sh. Note detected languages.

2. Survey the full repository before doing anything else:
   - **Exclude `.opencode/` and `.ai-layer/` from the survey entirely — these are MAG's own governance files, not the governed project. Do not draw any inferences about the project from their contents.**
   - Map the directory structure — note what exists, what's stubbed, what's empty
   - Search for any file matching *devplan*, *dev-plan*, *PRD*, *spec*, or *requirements* or similarly named file and read it
   - Search for any existing config files (package.json, pyproject.toml, docker-compose.yml,
     Dockerfile, .env.example, etc) and note what they reveal about the stack and intent
   - Read any README* files present
   - Search docs/, documentation/ for any planning or architecture documents and read them
   - Build a picture of: what this project is, what stack it uses, what stage it's at,
     and what the human intends to build
   - If no planning docs are found at all, note that explicitly

3. From the survey, immediately draft two working documents in memory (not written to disk yet):

   DRAFT PROJECT_CONFIG:
   ## Project Context
   - project_name: [from devplan/README or "unset"]
   - project_description: [from devplan/README or "unset"]
   - project_type: [infer from Dockerfile/tests presence or devplan]
   - governed_languages: [from project-init.sh output]
   - custom_models:
       planner: unset
       executor: unset
       reviewer: unset

   ## Operational Constraints
   - max_file_lines: 300
   - max_function_lines: 50

   ## Runtime Model Behaviour
   - compensating_constraints: none

   ## Data Sensitivity
   - data_sensitivity: [infer from .env/.example or keywords: health, finance, patient, personal]
   - sensitivity_reason: [what triggered the inference]

   Mark any field that genuinely cannot be inferred as "unset — needs input".
   If any significant aspect of the project cannot be mapped to the defined fields,
   create a new appropriately named field rather than forcing it into an ill-fitting
   one or omitting it.

   DRAFT ARCHITECTURE:
   ## What this system does
   - project_summary: [from devplan or README]

   ## Who uses it and how
   - users_and_context: [from devplan or README]

   ## Non-negotiable architectural patterns
   - patterns: [infer from repo structure, naming conventions, existing code]

   ## Non-negotiable constraints
   - constraints: [infer from existing config, linting, docker setup]

   ## Why this system exists (north star)
   - north_star: [from devplan goals if present]

   ## Data flow (sensitive data)
   - data_flow: [infer from structure or devplan]
   
   ## Project Ethos
   - project_ethos: [infer from patterns, constraints, north_star — what design philosophy does this system seem to be optimising for?]

   Mark any field that genuinely cannot be inferred as "unset — needs input".
   If any significant aspect cannot be mapped to defined fields, add a new
   appropriately named field rather than omitting it.

4. Use the draft state to identify genuine gaps — fields still marked "unset — needs input"
   that cannot proceed without human input. These become your questions. Do not ask about
   anything the survey already answered.

5. Infer defaults for the confirmation block:
   - project_type: if Dockerfile present → production; if tests/ dir exists → personal; else → exploratory
   - data_sensitivity: if .env or sensitive keywords found → sensitive; else → standard
   - For each detected language, prepare 2 default lint rules (module size + one pattern rule)

6. Present one confirmation block:
   PROJECT SETUP — INFERRED DEFAULTS
   ─────────────────────────────────────────
   Project type:      [inferred] ([reason])
   Data sensitivity:  [sensitive | standard] ([reason])
   Languages:         [detected list]
   Proposed rules:    [list — one line each, plain language] 
   ─────────────────────────────────────────
   Type:
   yes     — accept all defaults and proceed
   refine  — adjust specific items before proceeding

   If "yes": proceed with inferred values.
   If "refine": ask one DESIGN_STOP per item flagged for change. Only fire stops for
   items explicitly flagged.

6b.Present the full drafted PROJECT_CONFIG and ARCHITECTURE before emitting any DESIGN_STOP, so the human can see what was inferred and understand the
   context for each question. Even if everything is fully inferable still out put that same content and instead ask for confirmation or if user wants to
   make any changes.

7. If genuine gaps remain from step 4, emit a single DESIGN_STOP block with all of them
   numbered for one human reply. Do not fire them one at a time.

   Write every question in plain, natural language — no AI-sounding phrasing.
   Each question must include one sentence explaining what difference the answer makes.
   Where options make sense, offer 3 concrete suggestions drawn from the repo content,
   plus a fourth open option:
     "or go your own way — describe what you have in mind, including [the specific things
     the answer needs to cover]. A rough description is fine — enough to work from."
   When giving options label the one as (Recommended) based on your reasoning as to which is likely most optimal.
   And give this question about the Project Ethos:
     "Based on what I found, this system seems to be aiming for [inferred project_ethos statement]. Is that a reasonable ethos to work from when making implementation decisions, or would you describe it differently?"
   If no project ethos inferable so far, ask:
     "How would you describe the project philosophy/ethos for this system"

   This applies regardless of autonomy mode. Init friction is acceptable — it only
   happens once and genuine gaps need answering.

   If the survey answered everything, skip this step entirely.

   If a human response is too vague to act on, fire one targeted follow-up asking
   specifically for the missing detail before continuing.

8. Write .ai-layer/PROJECT_CONFIG.md to disk — merging the draft from step 3 with any
   DESIGN_STOP answers from step 7. Preserve the exact section header structure:
   ## Project Context, ## Operational Constraints, ## Runtime Model Behaviour,
   ## Data Sensitivity. Every field must reflect what was actually found or confirmed.
   Fields that still cannot be determined go in as "unset — update manually".

9. Write .ai-layer/ARCHITECTURE.md to disk — merging the draft from step 3 with any
   DESIGN_STOP answers from step 7. Preserve the exact section header structure:
   ## What this system does, ## Who uses it and how,
   ## Non-negotiable architectural patterns, ## Non-negotiable constraints,
   ## Why this system exists (north star), ## Data flow (sensitive data).
   This file gives any future agent a working understanding of the repo without
   needing to re-survey. Base every field on what was found or confirmed, not
   on defaults or assumptions. Fields that cannot be resolved go in as
   "unset — update manually".

10. For each confirmed lint rule:
    - Write the rule file to .ai-layer/lint-rules/tier-1/
    - Write a matching .rules.md explaining why this rule exists
    - Write to MCP memory: mcp_memory_create_entities with name matching the rule,
      entityType "constraint", observations ["rule: [description]", "project: [name]"]

11. Update docker/Dockerfile FROM line:
    Python primary  → python:3.12-slim
    Node/TS primary → node:20-slim
    Mixed           → python:3.12-slim  (human can override)

11b. Write the `permission` block to `opencode.json` for sensitive projects.

12. Append to decisions.md:
    DATE: [today] | INIT | project: [name] | languages: [list] | data_sensitivity: [value] | rules confirmed: [N]
