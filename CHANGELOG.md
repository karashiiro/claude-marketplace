# Changelog

## username-guard 1.0.0

Initial release of the username-guard plugin.

**New:**
- PreToolUse hook that rejects any file modification (Write / Edit / MultiEdit / NotebookEdit) whose written content contains the current username (the value of `$USER`), with an informative denial message
- Cross-platform pure-bash + awk implementation with an `id -un` fallback when `$USER` is unset; no jq/python/node dependency

## entrypoint-agents 1.0.0

Initial release of the entrypoint-agents plugin.

**New:**
- Added `main` agent defining the entrypoint philosophy for Claude Code sessions (problem-solving focus, correctness over simplicity, skill-first execution)

## uwuclaude 1.5.0

Initial release of the uwuclaude output style plugin.

**New:**
- SessionStart hook injects full uwuclaude style instructions at session startup
- UserPromptSubmit hook provides short style reminders on every user message to prevent drift in long sessions

## my-cool-proxy-extras 1.0.0

Initial release of the my-cool-proxy-extras plugin.

**New:**
- Added `research-strategist` agent for systematic research, analysis, and synthesis tasks using the MCP gateway
