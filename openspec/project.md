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
- **MapLibre GL JS** - Interactive map (globe projection)
- **deck.gl** - 3D extruded polygon markers
- **shadcn-vue** - Component library
- **Tolgee** - i18n translation management

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

- **RLS on every table** - Validate auth.uid() in SECURITY DEFINER functions
- **No business logic in frontend** - If you see game logic there, flag it
- **200 character description limit** - Enforced by DB constraint
- **Answer enum** - 'yes' | 'no' | 'not_sure' (not_sure only for questions)

## External Dependencies

- **Nominatim API** - Place search and enrichment (rate limited, be respectful)
- **CARTO Basemaps** - Map tiles (free tier)
- **Natural Earth** - Geographic region data
