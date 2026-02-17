Display Aegis diagnostic information for the current project.

When invoked, perform these checks and report results:

1. **Plugin Version**: Read version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`

2. **Detected Stacks**: Check the project root for:
   - `tsconfig.json` → TypeScript
   - `package.json` → Node.js
   - `pyproject.toml` / `setup.py` / `requirements.txt` → Python
   - `*.csproj` / `*.sln` → C# / .NET
   - `Cargo.toml` → Rust
   - `go.mod` → Go

3. **Test Framework**: Identify from package.json (vitest/jest/mocha), pyproject.toml (pytest), Cargo.toml, etc.

4. **Linter/Formatter**: Check for biome.json, eslint config, ruff.toml, rustfmt, gofmt presence.

5. **Active Bridges**: List which MCP servers from Aegis are available in this session (GitHub, Playwright, Context7, DeepWiki). For GitHub, note whether GITHUB_TOKEN is set.

6. **Project Memory**: Check if CLAUDE.md exists. If yes, report line count and last modified date.

7. **Git State**: Current branch, clean/dirty status, number of unpushed commits.

8. **Hooks Status**: Confirm that Aegis hooks are loaded (context-load on SessionStart, pre-push on PreToolUse).

Format the output as a clean, compact summary. Example:

```
⛡ Aegis v0.1.0

Stack:    TypeScript, Node.js
Tests:    vitest
Linter:   biome
Git:      main (clean, 0 unpushed)
Memory:   CLAUDE.md (47 lines, updated 2h ago)

Bridges:
  ✅ Playwright
  ✅ Context7
  ✅ DeepWiki
  ⚠️  GitHub (GITHUB_TOKEN not set)

Hooks:
  ✅ context-load (SessionStart)
  ✅ pre-push (PreToolUse/Bash)
```

$ARGUMENTS
