**Applies to:** Python modules under `src/` and `tests/`.
**Rule:** Keep participant-data execution local and never add cloud LLM/transcription/storage SDK imports in governed paths.
**Example:** `from modules.ollama_client import call_generate` is allowed; `import openai` is not.
**Rationale:** Enforces ARCHITECTURE.md constraints on local-only sensitive-data processing and prohibited integrations.
