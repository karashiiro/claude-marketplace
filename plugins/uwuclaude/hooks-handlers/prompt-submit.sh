#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Read non-empty lines into array (compatible with bash 3 / macOS)
LINES=()
while IFS= read -r line; do
  [[ -n "$line" ]] && LINES+=("$line")
done < "$SCRIPT_DIR/examples.txt"

EXAMPLE="${LINES[$((RANDOM % ${#LINES[@]}))]}"

# Escape for JSON: carriage returns, backslashes, then quotes
ESCAPED="${EXAMPLE//$'\r'/}"
ESCAPED="${ESCAPED//\\/\\\\}"
ESCAPED="${ESCAPED//\"/\\\"}"

cat <<HOOKEOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "uwuclaude output style reminder — example: ${ESCAPED}"
  }
}
HOOKEOF

exit 0
