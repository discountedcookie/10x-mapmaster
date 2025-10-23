# Quick Start - 10x-mapmaster

## TL;DR
Intelligent geography guessing game using **Vue 3 + TypeScript + Supabase + pgvector + MapLibre**. Players describe places, system uses vector embeddings + yes/no questions to identify them. Pure algorithmic filtering (pgvector + PostGIS), no hardcoded logic.

## START HERE Checklist

### First-Time Agent
- [ ] Read `02-current-state` - understand latest milestone
- [ ] Read `workflow-safety-rules` - NEVER run seed scripts or production commands
- [ ] Read `workflow-routing` - when to use Zen vs local vs ask user
- [ ] Read `tech-stack` - understand core architecture

### Returning Agent
- [ ] Read `02-current-state` - what changed since last session
- [ ] Check git status - any staged changes?
- [ ] Run `npm run dev` - verify local environment works

### Before Database Work
- [ ] Read `workflow-database` - migration patterns, seed workflow
- [ ] SAFE: `npx supabase db reset` (local only)
- [ ] NEVER: `supabase db reset --remote` or seed scripts

### Before Code Changes
- [ ] Feature branch: `git checkout -b feature/<name>`
- [ ] Read `workflow-testing` - understand test stack
- [ ] Read `tech-code-standards` - non-negotiables

### Before Committing
- [ ] Run `/pre_commit_check` (Cursor command)
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

## When in Doubt
- **Read memories**: Check `00-memory-index` for guidance
- **Ask user**: Production DB ops, deployment, breaking changes
- **Use Zen**: Complex analysis, security reviews, refactoring