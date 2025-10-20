# 10x-mapmaster 🗺️

[![CI/CD](https://github.com/discountedcookie/10x-mapmaster/actions/workflows/ci.yml/badge.svg)](https://github.com/discountedcookie/10x-mapmaster/actions/workflows/ci.yml)
[![Security Scan](https://github.com/discountedcookie/10x-mapmaster/actions/workflows/security-scan.yml/badge.svg)](https://github.com/discountedcookie/10x-mapmaster/actions/workflows/security-scan.yml)

An intelligent geography guessing game that learns from every session. Describe a place, answer yes/no questions, and watch the game get smarter over time.

## What is this?

Think "20 questions" meets geography, powered by vector embeddings. Players describe a place (like "A huge, hot city of palaces and busy markets"), and the game asks strategic questions to narrow down what they're thinking of. Each game session makes the system smarter.

## How it works

- 🧠 **Vector-powered matching** - Descriptions and questions use embeddings for semantic similarity
- 📍 **Real-time map** - See candidate places update as you answer questions
- 🌱 **Organic learning** - The system learns from player contributions
- ✅ **Place verification** - Uses OpenStreetMap Nominatim to validate real places

## Tech Stack

- **Frontend**: Vue 3 + TypeScript + Vite + shadcn-vue
- **Maps**: MapLibre GL JS
- **Backend**: Supabase (PostgreSQL + pgvector + Edge Functions)

## For AI Agents/Contributors

This project uses **Serena (MCP)** and structured documentation for tracking progress and design decisions.

### Starting Work on a Task

1. **Read architecture documentation**:
   - `AGENTS.md` - Product vision, architecture, and technical decisions
   - `CLAUDE.md` - Development guide, standards, and workflows
   
2. **Check Serena memories** (after activating project with `mcp_serena_activate_project`):
   ```
   mcp_serena_list_memories
   mcp_serena_read_memory project-setup-and-current-state
   ```
   
   Available memories:
   - `project-setup-and-current-state` - Current implementation status
   - `mvp2-complete-learning-system` - Latest milestone achievements
   - `design-decisions-log` - Architectural choices (with history)
   - `known-issues-and-gotchas` - Common problems and solutions

3. **Review coding standards**: See `CLAUDE.md` for Vue 3, TypeScript, and Supabase patterns

### Completing a Task

1. **Run quality checks**:
   ```bash
   npm run type-check  # TypeScript validation
   npm run lint        # Code linting
   npm test            # Unit and E2E tests
   ```

2. **Update Serena memories**:
   - Update `project-setup-and-current-state` (overwrite outdated sections)
   - Append to `design-decisions-log` (keep history with dates)
   - Append to `known-issues-and-gotchas` (never delete, only add)

### Memory Management Conventions

- **Current State**: OVERWRITE outdated sections to reflect current truth
- **Design Decisions**: APPEND new entries with dates, keep history
- **Issues/Gotchas**: APPEND problems and solutions, never delete

### MCP Servers Available

- **Context7** - Up-to-date documentation for Vue, Supabase, TypeScript, MapLibre, pgvector
- **Serena** - Code analysis, symbol search, and project knowledge management
- **Semgrep** - Security scanning and code analysis
- **Playwright** - Browser automation for E2E testing

### Key Files

- `AGENTS.md` - Product vision, architecture, database schema, design rationale
- `CLAUDE.md` - Development standards, workflows, common patterns
- `DEPLOYMENT.md` - Deployment guide for GitHub Pages + Supabase

## License

MIT

