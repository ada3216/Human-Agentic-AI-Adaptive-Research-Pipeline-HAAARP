#!/usr/bin/env bash
# scripts/state.sh — read/write .ai-layer/state.json
# Usage:
#   bash scripts/state.sh get <field>
#   bash scripts/state.sh set <field> <value>
#   bash scripts/state.sh show
#   bash scripts/state.sh validate
#   bash scripts/state.sh migrate
set -euo pipefail

STATE_FILE=".ai-layer/state.json"
CMD="${1:-show}"
FIELD="${2:-}"
VALUE="${3:-}"

# CURRENT_SCHEMA: bump when a field is added; never remove fields.
CURRENT_SCHEMA=1
REQUIRED_FIELDS="schema_version phase autonomy implement_slot pending_review current_task last_completed_phase design_stop_pending design_stop_question"

[ -f "$STATE_FILE" ] || { echo "ERROR: $STATE_FILE not found. Run Phase 1 setup."; exit 1; }

case "$CMD" in
  get)
    [ -z "$FIELD" ] && { echo "ERROR: field name required"; exit 1; }
    python3 - "$STATE_FILE" "$FIELD" << 'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
val = d.get(sys.argv[2])
if val is None:
    print("null")
elif isinstance(val, bool):
    print("true" if val else "false")
else:
    print(val)
PYEOF
    ;;
  set)
    [ -z "$FIELD" ] && { echo "ERROR: field name required"; exit 1; }
    python3 - "$STATE_FILE" "$FIELD" "$VALUE" << 'PYEOF'
import json, sys
state_file, field, raw = sys.argv[1], sys.argv[2], sys.argv[3]
with open(state_file) as f:
    d = json.load(f)
# Type coercion order: bool/null literals → integer → float → fall through to string
if raw == "true":      val = True
elif raw == "false":   val = False
elif raw == "null":    val = None
else:
    try:               val = int(raw)
    except ValueError:
        try:           val = float(raw)
        except ValueError:
                       val = raw
d[field] = val
with open(state_file, "w") as f:
    json.dump(d, f, indent=2)
print(f"state: {field} = {repr(val)}")
PYEOF
    ;;
  show)
    python3 - "$STATE_FILE" << 'PYEOF'
import json, sys
for k, v in json.load(open(sys.argv[1])).items():
    print(f"  {k}: {v}")
PYEOF
    ;;
  validate)
    # Verify state.json is parseable, has all required fields, and matches CURRENT_SCHEMA.
    # Exits 0 on valid, 1 on any problem with a clear remediation message.
    python3 - "$STATE_FILE" "$CURRENT_SCHEMA" "$REQUIRED_FIELDS" << 'PYEOF'
import json, sys
state_file, expected_schema, required = sys.argv[1], int(sys.argv[2]), sys.argv[3].split()
try:
    d = json.load(open(state_file))
except json.JSONDecodeError as e:
    print(f"INVALID: JSON parse error at line {e.lineno} col {e.colno}: {e.msg}")
    print(f"Recover: git show HEAD:{state_file} > {state_file}")
    sys.exit(1)
missing = [f for f in required if f not in d]
if missing:
    print(f"INVALID: missing fields: {missing}")
    print(f"Recover: bash scripts/state.sh migrate (adds missing fields with safe defaults)")
    sys.exit(1)
schema = d.get("schema_version")
if not isinstance(schema, int):
    print(f"INVALID: schema_version is not an integer (got {type(schema).__name__}: {schema!r})")
    sys.exit(1)
if schema > expected_schema:
    print(f"INVALID: state.json schema_version={schema} but this Magentica build expects {expected_schema}.")
    print(f"This state.json was written by a newer Magentica. Update Magentica or check out a matching commit.")
    sys.exit(1)
if schema < expected_schema:
    print(f"WARN: state.json schema_version={schema}, expected {expected_schema}. Run: bash scripts/state.sh migrate")
    sys.exit(1)
print(f"state.json: valid (schema_version={schema}, all required fields present)")
PYEOF
    ;;
  migrate)
    # Add any missing required fields with safe defaults; bump schema_version to CURRENT_SCHEMA.
    # Safe defaults are conservative: nothing is set to a value that would unblock or skip work.
    python3 - "$STATE_FILE" "$CURRENT_SCHEMA" << 'PYEOF'
import json, sys
state_file, target_schema = sys.argv[1], int(sys.argv[2])
defaults = {
    "schema_version": target_schema,
    "phase": "idle",
    "autonomy": "informed-yolo",
    "implement_slot": "A",
    "pending_review": False,
    "current_task": None,
    "last_completed_phase": None,
    "design_stop_pending": False,
    "design_stop_question": None,
}
try:
    d = json.load(open(state_file))
except json.JSONDecodeError:
    print(f"ERROR: {state_file} is not parseable JSON. Cannot migrate. Recover from git first.")
    sys.exit(1)
added = []
for k, v in defaults.items():
    if k not in d:
        d[k] = v
        added.append(k)
old_schema = d.get("schema_version", 0)
d["schema_version"] = target_schema
with open(state_file, "w") as f:
    json.dump(d, f, indent=2)
if added:
    print(f"migrated: added {added}, schema_version {old_schema} → {target_schema}")
else:
    print(f"migrated: no missing fields, schema_version {old_schema} → {target_schema}")
PYEOF
    ;;
  *)
    echo "Usage: state.sh [get <field> | set <field> <value> | show | validate | migrate]"
    exit 1
    ;;
esac
