# Aegis

**Structured AI development framework for Claude Code.**

Aegis brings discipline without dogma to AI-assisted development. Three principles, nine specialized agents, automatic quality gates — all packaged as a single Claude Code plugin.

---

## What It Does

Aegis makes Claude Code better at writing production code by enforcing three pillars:

- **Epistemic Rigor** — Verify before assuming. Read code before modifying it. Admit uncertainty.
- **Total Ownership** — You touch it, you own it. Boy Scout Rule applies. No blame-shifting.
- **Structured Feedback** — Every action produces information. Full outputs, captured learnings.

On top of that, Aegis provides:

- **Adaptive complexity** — Tasks are assessed on a 0–4 scale. Typo fixes get zero overhead. System designs get structured plans and specialized agents.
- **9 specialized agents** — Architect, Quality, Security, Frontend, Backend, Database, DevOps, Performance, Documentation. Invoked automatically at Level 3–4.
- **Pre-push quality gates** — Automatic linting, type checking, testing, and secrets scanning before any `git push`. Stack-aware (TypeScript, Python, C#, Rust, Go).
- **4 MCP bridges** — GitHub, Playwright, Context7, DeepWiki.

---

## Installation

### From marketplace

```
/plugin marketplace add Kan-Bull/aegis
/plugin install aegis@aegis-marketplace
```

### Direct install from GitHub

```bash
git clone https://github.com/Kan-Bull/aegis.git
claude --plugin-dir ./aegis
```

### GitHub bridge (optional)

Set your token so the GitHub MCP works:

```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxx
```

Playwright, Context7, and DeepWiki work without tokens.

---

## What's Inside

```
aegis/
├── .claude-plugin/plugin.json    # Plugin manifest
├── agents/                       # 9 specialized agents
│   ├── architect.md
│   ├── quality.md
│   ├── security.md
│   ├── frontend.md
│   ├── backend.md
│   ├── database.md
│   ├── devops.md
│   ├── performance.md
│   └── documentation.md
├── hooks/hooks.json              # Lifecycle hooks
├── scripts/
│   ├── context-load.sh           # Session startup — detect stack & context
│   └── pre-push.sh               # Pre-push — gates & secrets scan
├── skills/aegis-core/SKILL.md    # Core behavioral framework
├── commands/status.md            # /aegis:status diagnostic
├── .mcp.json                     # MCP bridge configurations
└── README.md
```

---

## The Adaptive System

Every task is assessed on complexity:

| Level | Overhead | Execution | Example |
|-------|----------|-----------|---------|
| **0 — Conversation** | None | Just respond | "What does this function do?" |
| **1 — Trivial** | None | Direct | Fix typo, add import |
| **2 — Simple** | Mental check | Direct | Modify a function, add a test |
| **3 — Moderate** | Mini-plan | Single agent | Implement a feature, add an endpoint |
| **4 — Complex** | Full plan | Multi-agent | System design, migration, cross-cutting refactor |

The plan is shared with you for approval at Level 3–4. No surprise autonomous work.

---

## Agents

All agents are auto-discovered and available as subagents. The adaptive system selects them based on task context.

| Agent | Scope |
|-------|-------|
| **Architect** | System design, ADRs, API design, task decomposition |
| **Quality** | Testing strategy, test writing, code review |
| **Security** | Threat modeling, vulnerability audits, secrets detection |
| **Frontend** | Components, accessibility, responsive design, state management |
| **Backend** | Services, error handling, integrations, logging |
| **Database** | Schema design, queries, migrations, indexing |
| **DevOps** | CI/CD, containers, deployment, monitoring |
| **Performance** | Profiling, optimization, load testing |
| **Documentation** | READMEs, ADRs, API docs, runbooks, changelogs |

---

## Pre-Push Gates

When Claude runs `git push`, Aegis intercepts and runs:

1. **Secrets scan** — Regex patterns for AWS keys, JWT tokens, private keys, GitHub tokens, Slack tokens, hardcoded passwords.
2. **Stack-specific checks** — Detected automatically:
   - TypeScript: `tsc --noEmit` → biome/eslint → vitest/jest
   - Python: mypy/pyright → ruff → pytest
   - C#: `dotnet build` → `dotnet test`
   - Rust: `cargo check` → `cargo test`
   - Go: `go vet` → `go test`

If anything fails, the push is blocked with a clear error message.

---

## Commands

| Command | Description |
|---------|-------------|
| `/aegis:status` | Show detected stack, active bridges, memory state, hook status |

---

## Bridges

| Bridge | Token Required | Purpose |
|--------|---------------|---------|
| GitHub | `GITHUB_TOKEN` | Repos, issues, PRs, code search |
| Playwright | No | Browser automation, visual testing |
| Context7 | No | Library documentation lookup |
| DeepWiki | No | GitHub repository documentation |

---

## Philosophy

Aegis was born from [Han](https://github.com/TheBushidoCollective/han) (Bushido Collective), which proved that hooks, rules, and agents can transform AI-assisted development. But Han went behind a paywall, and some design choices deserved rethinking.

Aegis keeps what works, drops the ceremony, and adds what was missing — particularly the adaptive system that calibrates overhead to actual task complexity.

**Aegis is not:**
- Branding. No virtues to memorize — just principles that translate into verifiable behaviors.
- A straitjacket. The framework adapts to the task, not the other way around.
- A Han fork. Ground-up reconstruction with a different architecture.

---

## License

MIT
