#!/usr/bin/env bash
# scripts/project-init.sh — language detection and lint-check.sh generation
set -euo pipefail

echo "Detecting project languages..."
ADAPTERS=""

has_files() {
  find . -name "$1" ! -path "*/node_modules/*" ! -path "*/.git/*" \
    ! -path "*/__pycache__/*" 2>/dev/null | head -1 | grep -q .
}

has_files "*.ts"  && { echo "  TypeScript"; ADAPTERS="js-ts $ADAPTERS"; }
has_files "*.tsx" && ADAPTERS="js-ts $ADAPTERS"
has_files "*.js"  && { echo "  JavaScript"; ADAPTERS="js-ts $ADAPTERS"; }
has_files "*.py"  && { echo "  Python";     ADAPTERS="python $ADAPTERS"; }
has_files "*.sh"  && { echo "  Shell";      ADAPTERS="shell $ADAPTERS"; }

# Deduplicate
ADAPTERS=$(echo "$ADAPTERS" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' | xargs)

# Discover custom adapters
for adapter_file in scripts/lint-adapters/*.sh; do
  name=$(basename "$adapter_file" .sh)
  case "$name" in js-ts|python|shell) continue ;; esac
  [ -f "$adapter_file" ] && { echo "  Custom: $name"; ADAPTERS="$ADAPTERS $name"; }
done

ADAPTERS=$(echo "$ADAPTERS" | xargs)

if [ -z "$ADAPTERS" ]; then
  echo "No supported languages detected. No lint-check.sh generated."
  exit 0
fi

# Generate lint-check.sh
{
  echo "#!/usr/bin/env bash"
  echo "# Generated $(date -I) by project-init.sh. Re-run /project-init to regenerate."
  echo "set -uo pipefail"
  echo "LINT_FAIL=0"
  for adapter in $ADAPTERS; do
    echo "echo '--- $adapter ---'"
    echo "bash scripts/lint-adapters/${adapter}.sh || LINT_FAIL=\$((LINT_FAIL+1))"
  done
  echo "echo ''"
  echo "[ \"\$LINT_FAIL\" -eq 0 ] && echo 'lint: all passed' \
|| { echo \"lint: \$LINT_FAIL failed\"; exit 1; }"
} > scripts/lint-check.sh
chmod +x scripts/lint-check.sh

# Update PROJECT_CONFIG.md governed_languages field
python3 - "$(echo $ADAPTERS | tr ' ' ',')" << 'PYEOF'
import sys, re
langs = sys.argv[1]
content = open(".ai-layer/PROJECT_CONFIG.md").read()
content = re.sub(r"governed_languages:.*", f"governed_languages: {langs}", content)
open(".ai-layer/PROJECT_CONFIG.md", "w").write(content)
PYEOF

echo ""
echo "Generated scripts/lint-check.sh for: $ADAPTERS"
echo "Run /project-init in Magentica to configure project-specific lint rules."
