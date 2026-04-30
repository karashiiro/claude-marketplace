#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# JSON-encode the style file using awk (no python3 dependency)
ESCAPED="$(awk '
  BEGIN { ORS="" }
  {
    gsub(/\\/, "\\\\")
    gsub(/"/, "\\\"")
    gsub(/\t/, "\\t")
    gsub(/\r/, "")
    if (NR > 1) printf "\\n"
    print
  }
' "$SCRIPT_DIR/uwuclaude-style.txt")"

cat <<HOOKEOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${ESCAPED}"
  }
}
HOOKEOF

exit 0
