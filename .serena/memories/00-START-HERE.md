# Memory Index - 10x-mapmaster

This index provides a complete guide to all available memories with a clear read-priority matrix.

## Read-Priority Matrix

### 🔴 Always Read First (Tier 1)
Start here for every session:
- `01-quick-start` - TL;DR for returning agents, START HERE checklist
- `02-current-state` - Latest milestone, active work, recent changes

### 🟡 Read Before Working (Tier 2)
Essential workflows - read before making changes:
- `workflow-database` - Migration order, seed workflow, Supabase MCP patterns, daily reset routine
- `workflow-safety-rules` - Critical safety rules, production safeguards
- `workflow-testing` - Test stack, commands, RLS testing, when to use each type
- `workflow-routing` - When to delegate to Zen vs local vs ask user
- `workflow-serena-patterns` - Memory update patterns, when to use think_about_* tools

### 🟢 Read As Needed (Tier 3-6)

**Tier 3: Technical Reference** (for implementation work)
- `tech-stack` - Tech, patterns, file structure
- `tech-external-apis` - Nominatim rate limits, MapLibre lazy loading
- `tech-code-standards` - Non-negotiables, conventions, patterns

**Tier 4: Game Domain Logic** (for game mechanics work)
- `game-complete-flow` - End-to-end game flow
- `game-vector-system` - Embeddings, learning, place enrichment
- `game-question-system` - Question selection algorithm, effectiveness tracking

**Tier 5: Design Context** (for understanding architectural decisions)
- `design-architecture` - Major decisions, rationale, UI patterns, auth flow

**Tier 6: Troubleshooting** (when debugging)
- `diagnostics-known-issues` - Known bugs, workarounds, common gotchas
- `diagnostics-solutions` - Debugging patterns, solutions to common problems

## Quick Reference by Task Type

| Task Type | Read These |
|-----------|------------|
| **First time / Returning** | 01-quick-start, 02-current-state |
| **Database work** | workflow-database, workflow-safety-rules, tech-stack |
| **Frontend work** | tech-stack, tech-code-standards, design-architecture |
| **Game mechanics** | game-complete-flow, game-vector-system, game-question-system |
| **Bug fixing** | diagnostics-known-issues, diagnostics-solutions |
| **Testing** | workflow-testing, workflow-safety-rules |
| **Security/Auth** | workflow-safety-rules, design-architecture (auth section) |

## How to Use This Index
1. Always start with Tier 1 (quick-start + current-state)
2. Read Tier 2 workflows relevant to your task
3. Reference Tier 3-6 as needed
4. Use the Quick Reference table above for task-specific guidance