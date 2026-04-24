"""Example configuration blocks and CLI snippets for pipeline stages."""

# Integration Snippets

These examples show how the pipeline stages connect using the current configuration layout and local CLI tools.

## Shared configuration block

```yaml
model:
  provider: local
  backend: ollama
  model_name: qwen2.5-27b-instruct
  api_base: http://localhost:11434
  temperature: 0.3
  deterministic_temperature: 0.0
  seeds: [42, 99, 123]

sensitivity: special_category
pre_registration_doi: "https://osf.io/example1"

study:
  strand: IPA
  team_structure: solo
  academic_level: masters

stability_testing:
  seeded_reruns: 3
  deterministic_run: true
  alternate_model_optional: false

osf:
  deposit_required: true
  osf_api_base: https://api.osf.io/v2
```

## 1. Pre-flight and ingest

```bash
python src/agent/orchestrator.py --check-preflight
python src/modules/ingest_and_deid.py \
  --input tests/fixtures/synthetic_transcript_P01.json \
  --code-map local_participant_code_map.json
```

Use this stage after confirming `artifacts/dpia_signed.json` exists for special-category studies.

## 2. Pass 1 blind analysis

```bash
python src/agent/pass1_runner.py \
  --deid-path artifacts/deidentified_P01_session1.json \
  --dataset-id SYNTHETIC_P01
```

This writes the blind-pass output and its local anchor.

## 3. Anchor deposit before Pass 2

```bash
python src/modules/osf_uploader.py \
  --anchor artifacts/pass1_anchor_SYNTHETIC_P01.json \
  --doi https://osf.io/example1
```

This upgrades the anchor so Pass 2 can proceed.

## 4. Lens dialogue and lock

```bash
python src/modules/lens_dialogue.py \
  --dataset-id SYNTHETIC_P01 \
  --researcher-id https://orcid.org/0000-0000-0000-0000

python src/modules/lens_dialogue.py \
  --lock \
  --run-id LENS_RUN_001 \
  --researcher-id https://orcid.org/0000-0000-0000-0000
```

The first command captures reflexive input. The second locks the lens for the positioned pass.

## 5. Pass 2 and grounding verification

```bash
python src/agent/pass2_runner.py \
  --anchor artifacts/pass1_anchor_SYNTHETIC_P01.json \
  --lens artifacts/lens_LENS_RUN_001.json

python src/modules/grounding_checker.py \
  --pass2-output artifacts/pass2_output_seeded0_SYNTHETIC_P01.json
```

Grounding records remain incomplete until a human sets verdicts.

## 6. Human review and audit emit

```bash
REVIEWER_ID=https://orcid.org/0000-0000-0000-0000 \
python src/tools/review_cli.py --dir artifacts/

python src/modules/audit_emitter.py \
  --dataset-id SYNTHETIC_P01 \
  --run-id LENS_RUN_001
```

The audit emitter packages only governed artifacts after all evidence verdicts are complete.

## 7. Delta comparison handoff

```bash
python - <<'PY'
from pathlib import Path
from src.modules.ollama_client import call_generate

prompt = Path('src/prompts/pass1_vs_pass2_delta_prompt.txt').read_text()
filled = (
    prompt.replace('{pass1_output}', Path('artifacts/pass1_output_SYNTHETIC_P01.json').read_text())
    .replace('{pass2_output}', Path('artifacts/pass2_output_seed42_SYNTHETIC_P01.json').read_text())
    .replace('{lens_summary}', Path('artifacts/lens_LENS_RUN_001.json').read_text())
)

print(call_generate(
    api_base='http://localhost:11434',
    model='qwen2.5-27b-instruct',
    system_prompt=filled,
    user_prompt='Produce the delta report in Markdown.',
    temperature=0.0,
    expect_json=False,
))
PY
```

Use this pattern to compare blind and positioned passes locally before supervisor handover.
