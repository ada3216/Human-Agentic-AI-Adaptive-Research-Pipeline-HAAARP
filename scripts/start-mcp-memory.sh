#!/usr/bin/env bash
set -euo pipefail

ENTRY="node_modules/@modelcontextprotocol/server-memory/dist/index.js"

if [ ! -f "$ENTRY" ]; then
  echo "ERROR: MCP memory server dependency missing: $ENTRY" >&2
  echo "Run: npm install" >&2
  echo "This repository keeps MCP dependencies at the repo root alongside package-lock.json." >&2
  exit 1
fi

exec node "$ENTRY"
