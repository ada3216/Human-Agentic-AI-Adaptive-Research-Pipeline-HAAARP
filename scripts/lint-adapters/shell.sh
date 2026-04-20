#!/usr/bin/env bash
# Lint adapter: Shell (ShellCheck)
set -uo pipefail

command -v shellcheck &>/dev/null || { echo "SKIP: shellcheck not installed"; exit 0; }

find . -name "*.sh" \
  ! -path "*/node_modules/*" ! -path "*/.git/*" \
  -exec shellcheck --severity=warning {} + 2>&1 || exit 1
