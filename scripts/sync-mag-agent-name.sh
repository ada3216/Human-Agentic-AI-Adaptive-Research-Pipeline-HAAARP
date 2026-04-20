#!/usr/bin/env bash
# scripts/sync-mag-agent-name.sh — sync Mag agent name to active auth account
set -euo pipefail

AUTH_FILE="$HOME/.local/share/opencode/auth.json"
MAG_FILE=".opencode/agents/mag.md"
CONFIG_FILE="opencode.json"

if [[ ! -f "$AUTH_FILE" ]]; then
  echo "ERROR: auth.json not found at $AUTH_FILE"
  exit 1
fi

if [[ ! -f "$MAG_FILE" ]]; then
  echo "ERROR: missing $MAG_FILE"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: missing $CONFIG_FILE"
  exit 1
fi

ACCOUNT_NAME=$(python3 - "$AUTH_FILE" << 'PYEOF'
import json, re, sys

data = json.load(open(sys.argv[1]))
if not isinstance(data, dict) or not data:
    print("unknown")
    raise SystemExit

first = next(iter(data.values()))
name = "unknown"
if isinstance(first, dict):
    raw = first.get("name")
    if isinstance(raw, str) and raw.strip():
        name = raw.strip().lower()

name = re.sub(r"[^a-z0-9-]+", "-", name)
name = re.sub(r"-+", "-", name).strip("-") or "unknown"
print(name)
PYEOF
)

AGENT_NAME="mag-${ACCOUNT_NAME}"

python3 - "$MAG_FILE" "$CONFIG_FILE" "$AGENT_NAME" << 'PYEOF'
import json, re, sys

mag_path, cfg_path, agent_name = sys.argv[1], sys.argv[2], sys.argv[3]

text = open(mag_path, "r", encoding="utf-8").read()
if not re.search(r"^name:\s+", text, flags=re.M):
    raise SystemExit(f"ERROR: no frontmatter name field in {mag_path}")

text = re.sub(r"^name:\s+.*$", f"name: {agent_name}", text, count=1, flags=re.M)
open(mag_path, "w", encoding="utf-8").write(text)

cfg = json.load(open(cfg_path, "r", encoding="utf-8"))
cfg["default_agent"] = agent_name
with open(cfg_path, "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PYEOF

echo "synced: name=${AGENT_NAME}"
