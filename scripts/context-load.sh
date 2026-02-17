#!/usr/bin/env bash
# Aegis — context-load hook
# Event: SessionStart
# Purpose: Silently gather project context and feed it back to Claude via stderr.
#
# Claude Code feeds stderr back into the conversation context.
# This hook reads the project structure so Claude starts every session informed.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# --- Detect stack ---
STACKS=""
[ -f "$PROJECT_DIR/tsconfig.json" ] && STACKS="${STACKS}typescript "
[ -f "$PROJECT_DIR/package.json" ] && STACKS="${STACKS}node "
[ -f "$PROJECT_DIR/pyproject.toml" ] || [ -f "$PROJECT_DIR/setup.py" ] || [ -f "$PROJECT_DIR/requirements.txt" ] && STACKS="${STACKS}python "
ls "$PROJECT_DIR"/*.csproj &>/dev/null && STACKS="${STACKS}csharp "
ls "$PROJECT_DIR"/*.sln &>/dev/null && STACKS="${STACKS}dotnet "
[ -f "$PROJECT_DIR/Cargo.toml" ] && STACKS="${STACKS}rust "
[ -f "$PROJECT_DIR/go.mod" ] && STACKS="${STACKS}go "

# --- Detect project memory ---
MEMORY="none"
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  MEMORY_LINES=$(wc -l < "$PROJECT_DIR/CLAUDE.md" | tr -d ' ')
  MEMORY="${MEMORY_LINES} lines"
fi

# --- Detect test framework ---
TESTS="unknown"
if [ -f "$PROJECT_DIR/package.json" ]; then
  if grep -q '"vitest"' "$PROJECT_DIR/package.json" 2>/dev/null; then
    TESTS="vitest"
  elif grep -q '"jest"' "$PROJECT_DIR/package.json" 2>/dev/null; then
    TESTS="jest"
  elif grep -q '"mocha"' "$PROJECT_DIR/package.json" 2>/dev/null; then
    TESTS="mocha"
  fi
fi
if [ -f "$PROJECT_DIR/pyproject.toml" ]; then
  if grep -q 'pytest' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
    TESTS="pytest"
  fi
fi

# --- Detect linter/formatter ---
LINTER="unknown"
if [ -f "$PROJECT_DIR/biome.json" ] || [ -f "$PROJECT_DIR/biome.jsonc" ]; then
  LINTER="biome"
elif [ -f "$PROJECT_DIR/.eslintrc.json" ] || [ -f "$PROJECT_DIR/.eslintrc.js" ] || [ -f "$PROJECT_DIR/eslint.config.js" ] || [ -f "$PROJECT_DIR/eslint.config.mjs" ]; then
  LINTER="eslint"
fi
if [ -f "$PROJECT_DIR/ruff.toml" ] || grep -q 'ruff' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
  LINTER="ruff"
fi

# --- Detect git state ---
GIT_BRANCH="none"
GIT_DIRTY="clean"
if [ -d "$PROJECT_DIR/.git" ]; then
  GIT_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "detached")
  if [ -n "$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null)" ]; then
    GIT_DIRTY="dirty"
  fi
fi

# --- Output to stderr (Claude sees this) ---
echo >&2 "[Aegis] Session context loaded"
echo >&2 "  Stack: ${STACKS:-none detected}"
echo >&2 "  Tests: ${TESTS}"
echo >&2 "  Linter: ${LINTER}"
echo >&2 "  Memory: ${MEMORY}"
echo >&2 "  Git: ${GIT_BRANCH} (${GIT_DIRTY})"
