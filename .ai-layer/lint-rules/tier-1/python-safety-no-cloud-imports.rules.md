**Applies to:** All `.py` files in `src/`

**Rule:** Do not import prohibited cloud API packages (`openai`, `anthropic`, `langchain`, `llamaindex`, `assemblyai`, `deepgram`, `boto3`, `google.cloud`, `cohere`, `replicate`, `huggingface_hub`). Ruff's bandit rules flag risky imports; supplement with `grep -r` in CI for explicit package names.

**Example:**
```python
# CORRECT — local-only LLM call
from modules.ollama_client import generate

# WRONG — sends data to external servers
import openai
```

**Rationale:** ARCHITECTURE.md § Prohibited integrations; GUARDRAILS.md HARD LIMIT 2. Participant data may be GDPR Article 9 special-category — external API calls may be a lawful processing violation.
