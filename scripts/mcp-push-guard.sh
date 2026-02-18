#!/usr/bin/env bash
# Aegis — MCP push guard
# Event: PreToolUse (matcher: mcp__github__push_files, mcp__github__create_or_update_file)
# Purpose: Block direct MCP pushes so they go through the git push gate instead.
#
# Exit code 2 = block the tool call

echo >&2 "[Aegis] 🚫 Direct MCP push blocked."
echo >&2 "[Aegis] Use 'git add + git commit + git push' instead so quality gates can run."
echo >&2 "[Aegis] The pre-push hook will verify types, lint, tests, and secrets before pushing."
exit 2
