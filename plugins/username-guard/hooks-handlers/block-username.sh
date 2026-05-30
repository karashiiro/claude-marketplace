#!/usr/bin/env bash

# PreToolUse hook: reject any file-modifying tool call whose written content
# contains the current username (the value of $USER) as a whole word,
# case-insensitively. This guards against accidentally leaking your local
# username into files. Whole-word, case-insensitive matching avoids false
# positives on short/common usernames (e.g. "ben" inside "benefit").
#
# Reads the hook payload as JSON on stdin, inspects the fields that carry
# written content (content / new_string / new_source — covering Write, Edit,
# MultiEdit and NotebookEdit), and emits a PreToolUse "deny" decision when the
# username is found. Otherwise it stays silent so the normal permission flow
# applies.
#
# Cross-platform: pure bash (3.x+) plus awk, with no jq/python/node dependency.

set -euo pipefail

# Determine the current username: prefer $USER, fall back to `id -un` (which is
# available on both macOS and Linux and works even when $USER is unset).
USERNAME="${USER:-}"
if [ -z "$USERNAME" ]; then
  USERNAME="$(id -un 2>/dev/null || true)"
fi

# Read the entire hook payload from stdin.
PAYLOAD="$(cat)"

# Without a username there is nothing to match against; let the call proceed.
if [ -z "$USERNAME" ]; then
  exit 0
fi

# Use awk to scan the JSON for content fields containing the username. On a
# match it prints three lines: "MATCH", the matched field name, and the target
# file path (best-effort, for a friendlier message). No match -> no output.
RESULT="$(printf '%s' "$PAYLOAD" | awk -v user="$USERNAME" '
  # Read the whole payload as a single record (JSON may span multiple lines).
  BEGIN { RS = "\1" }
  { j = $0 }

  # Return the string value of the first occurrence of "key" at/after frompos.
  # G_end (global) is set to the index just past the value, or 0 if not found.
  function valrange(key, frompos,    n, kp, i, k, c, st) {
    n = length(j)
    kp = index(substr(j, frompos), "\"" key "\"")
    if (kp == 0) { G_end = 0; return "" }
    # Position just after the closing quote of the key name.
    st = frompos + kp - 1 + length(key) + 2
    # Advance to the opening quote of the (string) value.
    i = st
    while (i <= n && substr(j, i, 1) != "\"") i++
    if (i > n) { G_end = 0; return "" }
    i++
    # Walk to the closing quote, skipping escaped characters.
    k = i
    while (k <= n) {
      c = substr(j, k, 1)
      if (c == "\\") { k += 2; continue }
      if (c == "\"") break
      k++
    }
    G_end = k + 1
    return substr(j, i, k - i)
  }

  # A "word" character for boundary purposes (standard \b semantics).
  function isword(c) { return (c ~ /[A-Za-z0-9_]/) }

  # Case-insensitive, whole-word search for u within v. Returns 1 if u occurs
  # in v not flanked by word characters on either side, else 0.
  function wordmatch(v, u,    lv, lu, n, m, off, p, before, after) {
    lv = tolower(v); lu = tolower(u)
    n = length(lv); m = length(lu)
    if (m == 0) return 0
    off = 1
    while (1) {
      p = index(substr(lv, off), lu)
      if (p == 0) return 0
      p = p + off - 1
      before = (p > 1)     ? substr(lv, p - 1, 1) : ""
      after  = (p + m <= n) ? substr(lv, p + m, 1) : ""
      if (!isword(before) && !isword(after)) return 1
      off = p + 1
    }
  }

  END {
    # Best-effort target path for the message.
    path = valrange("file_path", 1)
    if (path == "") path = valrange("notebook_path", 1)

    # Content-bearing fields across Write / Edit / MultiEdit / NotebookEdit.
    split("content new_string new_source", keys, " ")
    matched = ""
    for (ki = 1; ki in keys; ki++) {
      key = keys[ki]
      pos = 1
      while (1) {
        v = valrange(key, pos)
        if (G_end == 0) break
        if (wordmatch(v, user)) { matched = key; break }
        pos = G_end
      }
      if (matched != "") break
    }

    if (matched != "") {
      print "MATCH"
      print matched
      print path
    }
  }
')"

# No match: stay silent and let the normal permission flow proceed.
if [ -z "$RESULT" ]; then
  exit 0
fi

# Parse the awk output (line 1: MATCH, line 2: field, line 3: path).
{
  read -r _marker
  read -r FIELD
  read -r FPATH
} <<EOF
$RESULT
EOF

# JSON-escape a string for safe inclusion in the output below.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Build the human-readable reason with real quotes, then JSON-escape it once so
# any quotes/backslashes from the path, field, or username are handled uniformly.
REASON="Blocked by username-guard: the content being written to \"${FPATH:-the target file}\" contains your username (\"${USERNAME}\") in the '${FIELD}' field. Remove or replace the username before writing. (\$USER resolved to \"${USERNAME}\".)"
REASON="$(json_escape "$REASON")"

cat <<HOOKEOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "${REASON}"
  }
}
HOOKEOF

exit 0
