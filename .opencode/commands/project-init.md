---
name: project-init
agent: planner
---
Goal: produce `.ai-layer/PROJECT_CONFIG.md` and `.ai-layer/ARCHITECTURE.md`
that let a future agent work safely without re-surveying the repo.
Success test:
- A competent developer reading only those two files can tell:
  - what the PRODUCT is
  - where PRODUCT source lives
  - what runtime/test/build regime applies
  - what constraints, gates, and prohibited integrations exist
  - how data moves and what may not leave the system
  - what phase the repo is in
1. Run `bash scripts/project-init.sh`.
   - Treat detected languages as raw signal only.
   - If the script fails because `.ai-layer/PROJECT_CONFIG.md` does not exist, or
     if it rewrites `governed_languages` incorrectly, continue. Final values come
     from this command, not the script.
2. Classify every top-level directory and root file by PURPOSE.
   PRODUCT
   - The actual system this repo exists to build, run, or ship.
   - Typical examples: `src/`, `app/`, `lib/`, `api/`, `backend/`, `frontend/`,
     `tests/`, `config/`, `artifacts/`, `schemas/`, runtime docs, deployment files.
   IMPLEMENTATION GOVERNANCE
   - Files that constrain how PRODUCT may be built, tested, reviewed, or deployed.
   - Typical examples: `GUARDRAILS.md`, `COPILOT_INSTRUCTIONS.md`,
     `.github/workflows/*.yml`, `CONTRIBUTING.md`, policy/compliance docs,
     security/safety docs.
   FRAMEWORK
   - Files that operate the AI workflow around the repo rather than the PRODUCT.
   - Typical examples: `.opencode/`, `.ai-layer/`, Magentica agent files,
     command files, state/retry/session scripts.
   Rules:
   - Classify by purpose, not path name.
   - CI workflows default to IMPLEMENTATION GOVERNANCE, not FRAMEWORK.
   - If the repo itself is a framework/tooling product, those files may be PRODUCT.
   - `scripts/` are PRODUCT only when they directly execute, preprocess, deploy,
     or package the PRODUCT itself. Repo workflow, lint wrapper, integrity,
     init, state, retry-budget, session, and agent scripts are FRAMEWORK or
     IMPLEMENTATION GOVERNANCE by purpose.
   - Empty or planned top-level directories named in README, devplan, or specs
     still count as repo surfaces. List them and mark them as active, stubbed,
     or empty/planned rather than omitting them.
   - `PROJECT_CONFIG.md` and `ARCHITECTURE.md` must be derived from PRODUCT and
     IMPLEMENTATION GOVERNANCE sources. Do not describe FRAMEWORK files as product
     architecture unless the repo itself is explicitly about that framework.
3. Survey the repo in full before drafting anything.
   a. DIRECTORY MAP
   - Walk the full tree.
   - Tag each top-level directory and major root file as PRODUCT,
     IMPLEMENTATION GOVERNANCE, or FRAMEWORK.
   - Note what exists, what is stubbed, what is empty, what is clearly active.
   b. IDENTITY
   - Read every `README*` file.
   - Read root docs that define purpose, usage, or licensing.
   - Extract: what the PRODUCT is, who uses it, how it runs, and project maturity.
   c. PLANS / SPECS / PROPOSALS
   - Search for and read files matching:
     `*devplan*`, `*dev-plan*`, `implentation-docs/magentica-2-devplan-v5.md`, `*plan*`, `*prd*`, `*spec*`, `*requirements*`,
     `*roadmap*`, `*architecture*`, `*design*`, `*implementation*`,
     `*proposal*`, `*protocol*`, `*methods*`, `*ethics*`, `*study*`, `*grant*`.
   - Include readable PDF/DOCX/HTML exports if that is where the planning docs live.
   - If a phased devplan exists, extract:
     - current phase completed
     - next phase
     - key acceptance criteria
   - If no planning docs exist, note that explicitly.
   d. RUNTIME / DEPENDENCIES / VERIFICATION
   - Read where present:
     - `requirements.txt`, `pyproject.toml`, `package.json`, `go.mod`, `Gemfile`
     - `Dockerfile`, `docker-compose.yml`
     - `.env.example`, `.env.sample`, `config/*.yaml`, `config/*.example.*`,
       `secrets.example.*`
     - `Makefile`
   - Extract:
     - runtime stack
     - localhost endpoints
     - external APIs/services
     - lint/test/build commands
     - required env vars or flags
     - dependency pinning
     - network assumptions for tests and normal runs
   e. IMPLEMENTATION GOVERNANCE
   - Read in full where present:
     - `GUARDRAILS.md`
     - `COPILOT_INSTRUCTIONS.md`
     - `AGENTS.md`
     - `.github/AGENT-SYSTEM.md`
     - `.github/workflows/*.yml`
     - any root/doc file implying rules, safety, compliance, contributor rules,
       or AI-assistant rules
   - Extract:
     - hard limits
     - prohibited dependencies/integrations
     - required error handling
     - required verification behavior
     - data handling rules
     - artifact naming/integrity rules
     - dependency-change policy
     - atomic write requirements
     - append-only / immutability lock points
     - reviewer identity / approval semantics
     - reproducibility metadata requirements (model_config, prompt hash,
       seeds, versions)
     - filesystem safety rules (dataset_id validation, collision checks,
       path containment, raw-archive exclusion)
   f. PRODUCT SOURCE
   - Read representative files from actual PRODUCT source directories.
   - Extract:
     - primary modules / services / stages
     - error-handling pattern
     - data flow and storage pattern
     - naming conventions
     - gate / lock / sequencing logic
     - external calls or integrations
     - schema usage
   g. TESTS
   - Read test structure and representative test files.
   - Extract:
     - framework
     - mock/live strategy
     - required env vars
     - governance/safety assertions
     - network assumptions
   h. ARTIFACTS / SCHEMAS / EXAMPLES
   - Read schemas, example artifacts, and sample outputs where present.
   - Extract:
     - output locations
     - naming rules
     - hashing/signing/locking rules
     - immutability assumptions
4. Choose init mode.
   SURVEY MODE
   - Use when product source or meaningful runtime/config already exists.
   PROPOSAL MODE
   - Use when product source does not exist yet, but proposal/protocol/spec/research
     docs do exist.
   - Treat those docs as primary sources.
   - Do not treat absence of code as absence of requirements.
   BOOTSTRAP MODE
   - Use when there is no product source and no meaningful planning docs.
   - Do not infer architecture from absence.
5. For PROPOSAL MODE or BOOTSTRAP MODE, run a bootstrap interview before drafting.
   Interview rules:
   - Use plain language.
   - Explain implementation consequences/tradeoffs.
   - One concept per question.
   - Accept rough answers.
   - Offer `I don't know — recommend one` where useful.
   - In PROPOSAL MODE, prefill from the docs and ask only what is still missing.
   Ask:
   1. What does the tool/system need to do?
   2. Who will use it?
   3. What inputs or data will it handle?
   4. Is any of that data personal, health, financial, or otherwise sensitive?
   5. What outputs do you need?
   6. Where should it run: local script, local app, web app, API, or deployed service?
   7. Any preferred language, framework, or integration constraints? If not, say `recommend`.
   8. What checks, approvals, or human review steps must never be bypassed?
   Use the answers to draft intended architecture/config.
   - Empty repo: set `current_dev_phase: pre-scaffold — no product source yet`
   - Proposal-only repo: set `current_dev_phase: proposal-only — implementation not started`
6. Build an evidence table in memory.
   For every field you plan to write, keep:
   - field name
   - proposed value
   - source file(s) (repo-specific evidence with concrete file/section basis)
   - confidence: high | medium | low
   Rules:
   - Do not write unsupported claims.
   - If a value is supported only by FRAMEWORK files and not by PRODUCT or
     IMPLEMENTATION GOVERNANCE sources, do not treat it as product truth.
7. Draft `PROJECT_CONFIG.md` in memory. Use this exact section/header structure.
   `PROJECT_CONFIG.md` is the compact operational index. It provides identity,
   boundaries, runtime metadata, verification commands, env requirements,
   sensitivity classification, and a short constraint digest.
   Do not duplicate full prohibited-integration lists, artifact convention tables,
   or hard-gate tables in `PROJECT_CONFIG.md` when they are captured in
   `ARCHITECTURE.md`. If a structural rule has its canonical home in
   `ARCHITECTURE.md`, leave only a short digest or pointer in
   `PROJECT_CONFIG.md` compensating_constraints.
```markdown
## Project Context
- project_name: [from README/devplan/proposal/interview]
- project_description: [one sentence describing the PRODUCT, not the AI workflow]
- project_type: [explicit repo term if available; else infer]
- primary_language: [dominant PRODUCT source language only]
- governed_languages: [PRODUCT source languages only; see Step 9]
- runtime_stack: [specific runtime/execution model]
- current_dev_phase: [phase N of M | proposal-only — implementation not started | pre-scaffold — no product source yet | N/A | unset — needs input]
- repo_boundaries:
  - product_surface: [dirs/files]
  - implementation_governance: [dirs/files]
  - framework_tooling: [dirs/files]
- custom_models:
  - planner: unset — update manually
  - executor: unset — update manually
  - reviewer: unset — update manually
## Operational Constraints
- max_file_lines: 300
- max_function_lines: 50
- verification_commands:
  - lint: [command | unset — update manually]
  - test: [command | unset — update manually]
  - build: [command | N/A | unset — update manually]
- required_verification_env: [env vars / flags | none detected]
## Runtime Model Behaviour
- compensating_constraints:
  - [one bullet per high-signal rule from guardrails/policy/CI]
  - [keep short — full details are canonical in ARCHITECTURE.md]
  - [never write "none" if implementation-governance files exist]
## Data Sensitivity
- data_sensitivity: [sensitive | standard]
- sensitivity_reason: [specific evidence]
- legal_framework: [specific law/ethics/compliance basis | N/A | unset — needs input]
- data_egress_policy: [local-only | approved external only | standard | unset — needs input]
   Rules:
   - project_description must describe the PRODUCT, not the AI workflow.
   - primary_language and governed_languages must exclude FRAMEWORK-only languages.
   - runtime_stack must be specific.
   - Add new fields if a significant repo property does not fit cleanly.
   - Mark unresolved items unset — update manually.
8. Draft ARCHITECTURE.md in memory. Use these exact core headers:
   - What this system does
   - Who uses it and how
   - Non-negotiable architectural patterns
   - Non-negotiable constraints
   - Why this system exists (north star)
   - Data flow (sensitive data)
   - Project Ethos
   Add these sections whenever the evidence supports them:
   - Key Components
   - Hard gates
   - Prohibited integrations
   - Artifact conventions
   ARCHITECTURE.md is the canonical home for product patterns, hard gates,
   prohibited integrations, artifact conventions, and other reviewer-checkable
   invariants. For scaffold repos, label key components as implemented, partial,
   or planned when that status materially affects future implementation work.
   Hard scope rule:
   - Every sentence must help a future agent implement or modify the PRODUCT.
   - Do not describe the AI workflow around the repo as if it were the PRODUCT.
   - Do not include planner/reviewer flow, DESIGN_STOP, REVIEW_STOP, state.sh,
     MCP memory, retry budget, or .ai-layer/decisions.md as product architecture
     unless the repo itself is explicitly about those things.
   Use this exact drafting shape:
What this system does
- project_summary: product summary grounded in README/spec/source/interview
Who uses it and how
- users_and_context: actual end users/operators and interaction model
Key Components
- [component or stage]: [responsibility]
- if repo is proposal-only or bootstrap, planned components may be listed here and labelled planned
Non-negotiable architectural patterns
- patterns:
  - actionable implementation pattern
  - actionable implementation pattern
Non-negotiable constraints
- constraints:
  - specific prohibition or required behavior
  - specific prohibition or required behavior
Why this system exists (north star)
- north_star: core purpose that must not be traded away
Data flow (sensitive data)
- data_flow:
  - how data enters
  - how data transforms / stores / locks / exits
  - what may never leave the system, if relevant
Project Ethos
- project_ethos: design philosophy the system clearly optimises for
Hard gates
- gate name | trigger: condition | effect: block/warn | recovery: what user must do
Prohibited integrations
- [dependency/service]: [reason]
Artifact conventions
- [convention]: [detail]
   Rules:
   - patterns must be actionable.
   - constraints must be specific enough that a reviewer could detect drift.
   - For proposal-only or bootstrap repos, architecture may describe intended
     product structure, but it must still be grounded in proposal/interview answers.
   - Mark unresolved items unset — update manually.
9. Inference rules.
   project_type
   - Explicit README/devplan/interview wording wins over heuristics.
   - Else:
     - Docker/service/runtime + tests + clear shipping intent → production
     - tests + real source, mostly local/CLI/internal use → internal tool or library
     - mostly stubs/docs/phased scaffold → scaffold
     - proposal-only → planned tool or prototype
     - empty repo → prototype
   - If none fit well, add a better label instead of forcing a bad one.
   primary_language
   - Count PRODUCT source files only.
   - Do not copy project-init.sh output blindly.
   governed_languages
   - Include PRODUCT source languages only.
   - Include a script language only if scripts in that language directly execute,
     preprocess, deploy, or package the PRODUCT runtime.
   - Exclude languages used only for repo workflow, lint wrappers, integrity checks,
     init/state/session tooling, agent framework commands, or other FRAMEWORK
     or IMPLEMENTATION GOVERNANCE surfaces.
   - If unsure about scripts/, classify each script by purpose first and derive
     languages from that classification.
   data_sensitivity
   - Use the strongest evidence available: guardrails/spec/config/schema/example > keywords.
   - If sensitive, also infer legal_framework and data_egress_policy.
10. Generate lint rules using the 7-category framework.

    For each governed language, attempt to generate one rule per applicable
    category. Apply this in order:

    boundaries:    for each non-negotiable pattern, prohibited integration,
                   and hard gate condition in ARCHITECTURE.md that is
                   statically checkable — generate one rule
    safety:        required if data_sensitivity=sensitive; also generate
                   for any secret-handling or egress constraint found
    grep-ability:  read actual source files and identify dominant naming,
                   export, and import conventions — generate one rule
                   encoding the correct pattern
    glob-ability:  identify file placement conventions in source — generate
                   one rule if a clear pattern exists
    testability:   only if test files exist in the repo; enforce co-location
                   or async pattern found in existing tests
    observability: only if a logging pattern is identifiable in source;
                   encode the correct structured logging form
    docs:          only if a public API layer is identifiable; require
                   docstrings at that surface
    size:          1 rule per language, values from PROJECT_CONFIG.md
                   (max_file_lines, max_function_lines) — do not hardcode

    Do not generate a category rule if there is no evidence for it.
    Do not exceed 15 active rules per governed language.
    Do not generate rules for FRAMEWORK-only languages.

    Each rule requires two files:
      <language>-<category>-<descriptor>.<tool>.toml|json
        — valid executable tool configuration (not comments only)
      <language>-<category>-<descriptor>.rules.md
        — structured per P7-3 (Applies to / Rule / Example / Rationale):
          **Applies to:** [file types, contexts]
          **Rule:** [what to do — not just what to avoid]
          **Example:** [correct pattern in code]
          **Rationale:** [ARCHITECTURE.md section or Factory category reference]

    Note: scripts/lint-check.sh is a static file — do not regenerate it.
    Generate rules only.
11. Run self-check before presenting anything.
   Boundary check
   - Does governed_languages include FRAMEWORK-only languages?
   - Does project_description describe the AI workflow instead of the PRODUCT?
   - Does ARCHITECTURE.md mention planner/reviewer/state-machine concepts as product patterns?
   Coverage check
   - Can a future agent tell:
     - what the product is
     - where the product source lives
     - what runtime it uses
     - what lint/test/build commands matter
     - what env flags are required
     - what hard gates exist
     - what integrations are prohibited
     - how sensitive data moves
     - what phase the repo is in
     - what atomic write / lock / immutability rules apply
     - what model_config or prompt-hash metadata must be preserved
     - what filesystem/path safety checks are mandatory
     - what reviewer identity rules apply
   - If any answer is no, improve the drafts before showing them.
   Separation check
   - Are PROJECT_CONFIG.md and ARCHITECTURE.md clearly separated so that
     operational metadata is not duplicated as architecture and architectural
     rule tables are not duplicated as config?
   - If a long rule list appears in both files, move the canonical version to
     ARCHITECTURE.md and leave only a short digest or pointer in
     PROJECT_CONFIG.md.
12. Present one confirmation block, then show the full drafts.
   PROJECT SETUP — INFERRED DEFAULTS
   ─────────────────────────────────────────
   Project type:         value (reason)
   Primary language:     value (reason)
   Governed languages:   value (reason)
   Runtime stack:        value
   Current dev phase:    value
   Data sensitivity:     value (reason)
   Legal framework:      value
   Data egress:          value
   Product surface:      dirs/files
   Framework tooling:    dirs/files excluded from product architecture
   Verification:         lint=cmd | test=cmd | build=cmd
   Verification env:     env vars / flags
   Compensating rules:   N found
   Hard gates:           N found or none found
   Lint rules:           one per line
   ─────────────────────────────────────────
   yes     — accept all defaults and proceed
   refine  — adjust specific items before proceeding
   Then show:
   - full drafted PROJECT_CONFIG.md
   - full drafted ARCHITECTURE.md
13. If genuine gaps remain, emit one combined DESIGN_STOP block with numbered items
    for one reply.
   Rules:
   - Ask only genuine unresolved gaps and unresolved items that materially change implementation behavior.
   - Use plain language.
   - Explain implementation consequences/tradeoffs.
   - Explain why each answer matters.
   - Offer repo-grounded options where sensible.
   - Label the recommended option (Recommended).
   - Always ask about ethos if it is not confidently inferable.
   - If a reply is vague, ask one targeted follow-up before writing files.
14. Write .ai-layer/PROJECT_CONFIG.md from the confirmed draft.
   Hard rules:
   - governed_languages excludes FRAMEWORK-only languages
   - compensating_constraints is not none if implementation-governance files exist
   - runtime_stack is specific
   - current_dev_phase is filled if a phased devplan or proposal-only/bootstrap state exists
   - unresolved fields become unset — update manually
15. Write .ai-layer/ARCHITECTURE.md from the confirmed draft.
   Hard rules:
   - It describes the PRODUCT, not the AI workflow
   - patterns are actionable
   - constraints are reviewer-checkable
   - Include ## Hard gates, ## Prohibited integrations, and
     Artifact conventions whenever repo evidence supports them
   - unresolved fields become unset — update manually
16. For each confirmed lint rule:
   - write the rule file to .ai-layer/lint-rules/tier-1/
   - write a matching .rules.md
   - write to MCP memory:
     mcp_memory_create_entities
     - name: rule name
     - entityType: constraint
     - observations: ["rule: description", "project: name"]
17. If docker/Dockerfile exists, update its FROM line:
   - Python primary  → python:3.12-slim
   - Node/TS primary → node:20-slim
   - Mixed           → python:3.12-slim unless the human chooses otherwise
18. For sensitive projects, write this to opencode.json:
    "permission": { "edit": "ask", "bash": "ask" }
19. Append to .ai-layer/decisions.md:
    DATE: today | INIT | project: name | languages: list | data_sensitivity: value | rules confirmed: N
20. Commit all written files (mandatory final step):
   - `git add -A`
   - `bash scripts/check.sh`
   - `git commit -m "chore(init): project-init setup for [project_name]"`
     - Conventional commit: type(scope): description, present tense, under 72 chars
   - If `git status --porcelain` is non-empty after commit, surface residual files.
   - Rationale: project-init writes governed files that must be committed before any
     subsequent /plan or /implement can operate on a clean baseline.
