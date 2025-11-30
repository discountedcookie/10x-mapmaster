<!-- OPENSPEC:START -->

# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:

- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:

- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# 10x-Mapmaster: Agent Context

**Project:** Geographic guessing game with semantic embeddings and learning.

**Core Architecture:** Database-first. ALL business logic in PostgreSQL. Frontend is presentation only.

---

## Critical Rules

### Honesty Policy

**Never fabricate work.** If you can't do something:

1. Stop immediately
2. State what you cannot do and why
3. Present alternatives
4. Wait for user decision

### Database-First Architecture

| Layer        | Responsibilities                               | Does NOT Do                       |
| ------------ | ---------------------------------------------- | --------------------------------- |
| **Database** | Game mechanics, scoring, ranking, RLS, PostGIS | N/A - owns all logic              |
| **Frontend** | Presentation, user interaction, UI components  | Game logic, scoring, calculations |

**If you see game logic in frontend code, flag it.**

---

## Available Agents

### Primary (Tab to switch)

- **build** - Full development with all tools
- **plan** - Read-only analysis, no changes

### Subagents (@mention or automatic)

- **@supabase-expert** - Database schema, functions, RLS, pgvector, PostGIS
- **@frontend-expert** - Vue 3, shadcn-vue, presentation layer
- **@researcher** - Web research with exa + sequential thinking
- **@code-reviewer** - Quality review, architecture compliance

### Using Subagents

When invoking expert subagents (frontend-expert, supabase-expert):

1. Give them a specific, scoped task
2. After they return, use @code-reviewer to verify their work matches the request
3. Do NOT trust subagent summaries - they don't see their own blind spots

When invoking @code-reviewer:

- It reports. User decides what to fix.
- Do NOT immediately act on its findings without user approval.

---

## Database Workflow

**Source-based development:**

```
supabase/db/
├── schema/               # Schema definitions (tables, RLS, indexes)
├── game_logic/functions/ # Game mechanics, scoring, maintenance
└── public/functions/     # Player-facing RPC entrypoints
```

1. Edit source files in `supabase/db/schema/` or `supabase/db/{game_logic,public}/functions/`
2. Run `bun run db:rebuild` to generate migration + reset DB
3. Test with `supabase test db`
4. Commit both source files AND generated migration

**Never edit migrations directly** - edit source files instead.

---

## OpenSpec Workflow

Specs are in `openspec/specs/` directory. OpenSpec changes go in `openspec/changes/`.

---

## Key Directories

```
docs/           # Project specifications (source of truth)
src/            # Vue 3 frontend (presentation only)
supabase/db/    # Database source files (business logic)
supabase/functions/  # Edge functions (LLM, embeddings)
```
