#!/usr/bin/env bash
# Lint adapter: JavaScript + TypeScript (ESLint)
# Reads *.eslint.json rule files from .ai-layer/lint-rules/tier-1/
# Merges with defaults and runs ESLint against all JS/TS files.
set -uo pipefail
RULES_DIR=".ai-layer/lint-rules/tier-1"

command -v ./node_modules/.bin/eslint &>/dev/null || { echo "SKIP: eslint not installed (npm install)"; exit 0; }

CONFIG=$(mktemp /tmp/eslint-XXXXXX.json)
trap 'rm -f "$CONFIG"' EXIT

python3 - "$RULES_DIR" "$CONFIG" << 'PYEOF'
import json, os, sys, glob
rules_dir, out = sys.argv[1], sys.argv[2]
project_rules = {}
for f in glob.glob(os.path.join(rules_dir, "*.eslint.json")):
    try: project_rules.update(json.load(open(f)))
    except Exception as e: print(f"WARN: {f}: {e}")
defaults = {
    "max-lines": ["warn", {"max": 300, "skipBlankLines": True, "skipComments": True}],
    "max-lines-per-function": ["warn", {"max": 50, "skipBlankLines": True}]
}
json.dump({
    "rules": {**defaults, **project_rules},
    "env": {"es2022": True, "node": True},
    "parserOptions": {"ecmaVersion": 2022, "sourceType": "module"}
}, open(out, "w"))
PYEOF

./node_modules/.bin/eslint \
  --no-eslintrc --config "$CONFIG" \
  --ext .js,.ts,.jsx,.tsx,.mjs,.cjs \
  --ignore-pattern "node_modules" \
  --ignore-pattern ".opencode/plugins/gatekeeper.js" \
  . 2>&1 || exit 1
