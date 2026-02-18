#!/usr/bin/env bash
# Aegis — pre-push hook
# Event: PreToolUse (matcher: Bash)
# Purpose: Intercept `git push` commands and run quality gates before allowing.
#
# Reads JSON from stdin. If the command is not a git push, passes through.
# If it IS a git push, runs stack-appropriate checks and blocks on failure.
#
# Exit codes:
#   0 = allow the command
#   2 = block the command (stderr is shown to Claude)

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# --- Read stdin JSON ---
INPUT=$(cat)

# Use python3 for reliable JSON parsing (handles escaped quotes, special chars)
COMMAND=$(echo "$INPUT" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    cmd = data.get("tool_input", {}).get("command", "")
    print(cmd)
except:
    print("")
' 2>/dev/null || echo "")

# --- Only intercept git push ---
if ! echo "$COMMAND" | grep -qE 'git\s+push|gh\s+repo\s+create.*--push|gh\s+pr\s+merge'; then
  exit 0
fi

echo >&2 "[Aegis] Pre-push gate activated — running checks..."

FAILED=0

# ============================================================
# SECRETS SCAN (always runs)
# ============================================================
echo >&2 "[Aegis] Scanning for secrets..."

# Get staged/committed files that would be pushed
SECRETS_FOUND=0
PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*'
  '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'
  'gh[pousr]_[A-Za-z0-9_]{36,}'
  'xox[baprs]-[a-zA-Z0-9-]+'
)

# Scan only source files — exclude scripts, configs, lock files, node_modules
EXCLUDE_PATHS=':!*.sh :!*.lock :!node_modules :!*.json :!*.md :!.git'

for pattern in "${PATTERNS[@]}"; do
  if git -C "$PROJECT_DIR" grep -rlE "$pattern" -- $EXCLUDE_PATHS 2>/dev/null | head -5 | grep -q .; then
    echo >&2 "[Aegis] ⚠️  Potential secret detected matching: $pattern"
    SECRETS_FOUND=1
  fi
done

if git -C "$PROJECT_DIR" grep -rlE '(password|secret|api_key|apikey)\s*[=:]\s*["'\'''][^\s"'\'']{8,}' -- $EXCLUDE_PATHS 2>/dev/null | head -5 | grep -q .; then
  echo >&2 "[Aegis] ⚠️  Potential hardcoded credentials found in tracked files"
  SECRETS_FOUND=1
fi

if [ "$SECRETS_FOUND" -eq 1 ]; then
  echo >&2 "[Aegis] 🔴 BLOCKED — Potential secrets detected. Review before pushing."
  FAILED=1
fi

# ============================================================
# STACK-SPECIFIC GATES
# ============================================================

# --- TypeScript / JavaScript ---
if [ -f "$PROJECT_DIR/tsconfig.json" ]; then
  echo >&2 "[Aegis] Running TypeScript checks..."

  # Type check
  if command -v npx &>/dev/null; then
    if ! npx tsc --noEmit --pretty 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 TypeScript type check failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ TypeScript types OK"
    fi
  fi

  # Linter
  if [ -f "$PROJECT_DIR/biome.json" ] || [ -f "$PROJECT_DIR/biome.jsonc" ]; then
    if ! npx biome check "$PROJECT_DIR/src" 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 Biome lint failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Biome lint OK"
    fi
  elif [ -f "$PROJECT_DIR/eslint.config.js" ] || [ -f "$PROJECT_DIR/eslint.config.mjs" ] || [ -f "$PROJECT_DIR/.eslintrc.json" ] || [ -f "$PROJECT_DIR/.eslintrc.js" ]; then
    if ! npx eslint . 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 ESLint failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ ESLint OK"
    fi
  fi

  # Tests
  if grep -q '"vitest"' "$PROJECT_DIR/package.json" 2>/dev/null; then
    if ! npx vitest run 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 Vitest tests failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Tests passed"
    fi
  elif grep -q '"jest"' "$PROJECT_DIR/package.json" 2>/dev/null; then
    if ! npx jest --passWithNoTests 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 Jest tests failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Tests passed"
    fi
  fi
fi

# --- Python ---
if [ -f "$PROJECT_DIR/pyproject.toml" ] || [ -f "$PROJECT_DIR/setup.py" ] || [ -f "$PROJECT_DIR/requirements.txt" ]; then
  echo >&2 "[Aegis] Running Python checks..."

  # Type check
  if command -v mypy &>/dev/null; then
    if ! mypy "$PROJECT_DIR" 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 mypy type check failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ mypy OK"
    fi
  elif command -v pyright &>/dev/null; then
    if ! pyright "$PROJECT_DIR" 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 pyright type check failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ pyright OK"
    fi
  fi

  # Linter
  if command -v ruff &>/dev/null; then
    if ! ruff check "$PROJECT_DIR" 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 Ruff lint failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Ruff OK"
    fi
  fi

  # Tests
  if command -v pytest &>/dev/null; then
    if ! pytest "$PROJECT_DIR" --tb=short -q 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 pytest failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Tests passed"
    fi
  fi
fi

# --- C# / .NET ---
if ls "$PROJECT_DIR"/*.csproj &>/dev/null || ls "$PROJECT_DIR"/*.sln &>/dev/null; then
  echo >&2 "[Aegis] Running .NET checks..."

  if command -v dotnet &>/dev/null; then
    # Build
    if ! dotnet build --nologo -v q 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 dotnet build failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Build OK"
    fi

    # Tests
    if ! dotnet test --nologo -v q 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 dotnet test failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Tests passed"
    fi
  fi
fi

# --- Rust ---
if [ -f "$PROJECT_DIR/Cargo.toml" ]; then
  echo >&2 "[Aegis] Running Rust checks..."

  if command -v cargo &>/dev/null; then
    if ! cargo check 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 cargo check failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ cargo check OK"
    fi

    if ! cargo test 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 cargo test failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Tests passed"
    fi
  fi
fi

# --- Go ---
if [ -f "$PROJECT_DIR/go.mod" ]; then
  echo >&2 "[Aegis] Running Go checks..."

  if command -v go &>/dev/null; then
    if ! go vet ./... 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 go vet failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ go vet OK"
    fi

    if ! go test ./... 2>&1 | tail -20 >&2; then
      echo >&2 "[Aegis] 🔴 go test failed"
      FAILED=1
    else
      echo >&2 "[Aegis] ✅ Tests passed"
    fi
  fi
fi

# ============================================================
# RESULT
# ============================================================
if [ "$FAILED" -eq 1 ]; then
  echo >&2 ""
  echo >&2 "[Aegis] 🚫 Push blocked — fix the issues above before pushing."
  exit 2
fi

echo >&2 "[Aegis] ✅ All gates passed — push allowed."
exit 0
