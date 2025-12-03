# Project Context

## Purpose

10x-Mapmaster is an intelligent geography guessing game where players describe places, and the system asks strategic yes/no questions to identify them. The system learns from every session using semantic embeddings and accumulated gameplay knowledge.

## Tech Stack

### Backend

- **Supabase (PostgreSQL)** - Managed database with built-in auth and RLS
- **pgvector** - Vector similarity search for semantic matching
- **PostGIS** - Spatial operations and polygon handling
- **Edge Functions (Deno)** - External service integrations (LLM, embeddings)

### Frontend

- **Vue 3** with Composition API
- **Pinia** - State management
- **MapLibre GL JS** - Interactive map (globe projection, native layers for markers)
- **shadcn-vue** - Component library
- **vue-i18n** - Internationalization with ICU MessageFormat

### External Services

- **Ollama** (dev) / **Supabase gte-small** (prod) - 384d embeddings
- **LLM Provider** - Question generation, trait extraction
- **Nominatim** - Place enrichment and geometry

## Project Conventions

### Code Style

- TypeScript strict mode
- Prettier + ESLint (oxlint for fast feedback)
- Max 200 lines per file
- SQL: uppercase keywords, lowercase identifiers

### Architecture Patterns

**Database-First Design:**

- ALL business logic lives in PostgreSQL functions
- Frontend is presentation only - no game logic
- Data access via RPC calls: `supabase.rpc('function_name', params)`

**Source-Based Database Development:**

- Edit source files in `supabase/db/schema/` or `supabase/db/functions/`
- Run `bun run db:rebuild` to generate migration + reset DB
- Never edit migrations directly

### Testing Strategy

- **Database**: pgTAP via `supabase test db`
- **Unit**: Vitest for composables and stores
- **E2E**: Playwright (Chromium + mobile viewport)

### Git Workflow

- Feature branches for all changes
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`
- PR required for main, must pass CI

## Domain Context

### Game Flow

1. Player describes a place
2. System generates embedding, finds candidates
3. System asks yes/no questions to narrow candidates
4. When confident, system guesses the place
5. If wrong or max turns reached, player submits correct place
6. System learns from the session

### Key Concepts

- **Candidates** - Places matching the description, ranked by confidence
- **Traits** - Semantic characteristics of places (extracted by LLM)
- **Confidence** - Three metrics: top probability, margin, entropy
- **Learning** - New traits extracted from player descriptions

## Important Constraints

- **Hybrid security model** - SECURITY DEFINER for privileged ops (edge functions, private config), Invoker + RLS for user data
- **No business logic in frontend** - If you see game logic there, flag it
- **200 character description limit** - Enforced by DB constraint
- **Answer enum** - 'yes' | 'no' | 'not_sure' (not_sure only for questions)

## External Dependencies

- **Nominatim API** - Place search and enrichment (rate limited, be respectful)
- **CARTO Basemaps** - Map tiles (free tier)
- **Natural Earth** - Geographic region data

## OpenSpec Change Management

### When to Archive a Change

Archive a change when ANY of these apply:

1. **Complete** - All tasks done, specs merged into main specs
2. **Superseded** - A newer change replaces this approach
3. **Abandoned** - Technology decision changed or feature deprioritized
4. **Implemented Differently** - Code evolved past the spec; spec no longer reflects reality

### Archive Process

1. Update `tasks.md` to reflect actual completion state
2. Run `openspec archive <change-name>` to merge specs and move to archive
3. Use `--skip-specs` only for infrastructure/docs changes that don't add capabilities
4. For cancelled changes, add a `CANCELLED.md` explaining why

### Handling Partial Completion

- If core functionality is done but polish/tests are deferred, archive with tasks marked as "DEFERRED"
- If tasks were falsely marked complete, reset them before archiving or continuing work
- Never leave a change with misrepresented task status

### Change Naming

- Use descriptive kebab-case names: `add-feature-name`, `fix-bug-description`
- Prefix with number for sequencing if part of a series: `01-auth-basics`, `02-session-handling`
