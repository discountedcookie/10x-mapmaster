# Quick Start - 10x-mapmaster

## TL;DR
Intelligent geography guessing game using **Vue 3 + TypeScript + Supabase + pgvector + MapLibre**. Players describe places, system uses vector embeddings + yes/no questions to identify them. Pure algorithmic filtering (pgvector + PostGIS), no hardcoded logic.

## START HERE Checklist

### First-Time Agent
- [ ] Read `current-state.md` - understand latest milestone
- [ ] Read `workflows/safety-rules.md` - NEVER run seed scripts or production commands
- [ ] Read `workflows/git.md` - when to use feature branches vs main
- [ ] Read `technical/stack.md` - understand core architecture

### Returning Agent
- [ ] Read `current-state.md` - what changed since last session
- [ ] Check git status - any staged changes?
- [ ] Run `npm run dev` - verify local environment works

### Before Database Work
- [ ] Read `workflows/database.md` - migration patterns, seed workflow
- [ ] SAFE: `npx supabase db reset` (local only)
- [ ] NEVER: `supabase db reset --remote` or seed scripts

### Before Code Changes
- [ ] Feature branch: `git checkout -b feature/<name>`
- [ ] Read `workflows/testing.md` - understand test stack
- [ ] Read `technical/code-standards.md` - non-negotiables

### Before Committing
- [ ] Run tests and linting
- [ ] Commit: `git commit -m "feat(scope): description"`
- [ ] Push and create PR

## Daily Commands
```bash
npm run dev              # http://localhost:5173/10x-mapmaster/
npx supabase db reset    # SAFE - local DB only
npm run test:unit        # Unit tests (159/159 passing)
npm run test:db          # Database tests (25/25 passing)
npm run test:e2e         # E2E tests (local only)
npm run type-check       # TypeScript
npm run lint             # ESLint
npm run build            # Production build
```

## Project Structure
```
src/
  components/     # Vue components (game/, map/, ui/)
  composables/    # Reusable logic (useEmbeddings, usePlaces, useTheme)
  stores/         # Pinia stores (auth, game, places)
  lib/            # Utilities (places/, supabase, utils)
  views/          # Page components (GameView, HomeView, etc.)
  types/          # TypeScript types (database.ts)

supabase/
  migrations/     # Database schema (000001-000003)
  functions/      # Edge functions (generate-embedding)
  tests/          # pgTAP tests
```

## Core Principle
**Session-First Architecture**: Database is source of truth. Game session created immediately, all state derived from relations. Pure algorithmic filtering - no hardcoded business logic.

## Cline Workflow Pattern

### Starting a Session
1. Read relevant docs from `/.cline/docs/` based on task type
2. Query memory MCP for current state and recent changes
3. Review any new_task context if continuing previous work

### During Work
- Update memory MCP with observations as you learn/decide
- Use `think_about_*` tools for complex decisions
- Update docs only if architecture/workflows changed

### Ending a Session
- Update memory MCP with current state
- Use `new_task` if switching to different work (preserves full context)
- Update docs only if workflow/architecture changed

## When in Doubt
- **Read docs**: Check this README for guidance
- **Query memory**: Use memory MCP for current state
- **Ask user**: Production DB ops, deployment, breaking changes
