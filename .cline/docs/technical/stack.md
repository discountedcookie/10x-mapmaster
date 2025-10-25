# Technical Stack - 10x-mapmaster

## Core Stack

**Frontend Framework:**
- Vue 3 (Composition API)
- TypeScript (strict mode)
- Vite (build tool)
- Pinia (state management)
- Vue Router (routing)

**UI Framework:**
- shadcn-vue (component library)
- Tailwind CSS v4 (styling)
- Reka UI (headless components)
- Sonner (toast notifications)
- @vueuse/core (composable utilities)

**Maps:**
- MapLibre GL JS v5.9.0
- Alidade map styles (Smooth / Smooth Dark)
- PostGIS for server-side spatial queries

**Backend:**
- Supabase (BaaS)
  - PostgreSQL 15
  - pgvector extension (vector similarity)
  - PostGIS extension (geographic queries)
  - Auth (email/password)
  - Edge Functions (Deno)

**Embeddings:**
- Supabase AI
- gte-small model (384 dimensions)
- Cached in database as `vector(384)` type

**External APIs:**
- Nominatim (geocoding) - 1 req/sec rate limit
- Open-Meteo (weather data)
- Overpass (OpenStreetMap data)
- Wikipedia (place enrichment)

**Testing:**
- Vitest (unit tests)
- Playwright (E2E tests)
- pgTAP (database tests)
- @vue/test-utils (component testing)

**Development Tools:**
- ESLint (linting)
- TypeScript (type checking)
- Supabase CLI (local development)

## Core Principles

### 1. PostgREST Pattern
**Database does the work, frontend filters/presents**

Database-side:
- Vector similarity with pgvector
- Geographic filtering with PostGIS
- Candidate filtering logic
- Question selection algorithm
- Learning/effectiveness updates

Frontend-side:
- Display results
- User interaction
- State management
- Map visualization

**Benefits:**
- Scalable (DB optimized for heavy computation)
- Secure (RLS policies enforce access control)
- Consistent (single source of truth)
- Testable (pgTAP tests for DB logic)

### 2. Session-First Architecture
**Database is source of truth for all game state**

Pattern:
1. Create `game_session` immediately when user starts
2. Store all answers in `game_answers` table
3. Derive all state from database relations
4. No ephemeral frontend state for game flow

**Benefits:**
- Survives page refreshes
- Enables game replay/analysis
- Provides learning data
- Simplifies state management

### 3. Vector System
**Semantic similarity with cached embeddings**

Storage:
- `vector(384)` type in PostgreSQL
- HNSW indexing for fast similarity search
- Cached embeddings (no regeneration)

Usage:
- Place embeddings: Semantic representation of locations
- Question embeddings: Semantic representation of questions
- Description embeddings: User's input description

Operations:
- Cosine similarity: `<=>` operator
- Top-K nearest neighbors: `ORDER BY embedding <=> $1 LIMIT 20`
- Semantic filtering: Adjust confidence by question similarity

## File Structure

```
src/
  components/           # Vue components
    game/              # Game-specific components
      PlaceSearch.vue  # Place search input
      QuestionCard.vue # Question display
      ResultCard.vue   # Result display
    map/               # Map components
      MapView.vue      # MapLibre integration
    ui/                # shadcn-vue components
      button/          # Button component
      card/            # Card component
      ...
    ConfidenceBadge.vue
    FloatingNavbar.vue
    HeroCard.vue
    ThemeToggle.vue

  composables/          # Reusable composition functions
    useEmbeddings.ts   # Embedding generation
    usePlaces.ts       # Places data (singleton pattern)
    useTheme.ts        # Theme management

  stores/              # Pinia stores
    auth.ts            # Authentication state
    game.ts            # Game state machine
    places.ts          # Places state (legacy)

  lib/                 # Utilities and helpers
    places/            # Place-related utilities
      index.ts         # Main place utilities
      nominatim.ts     # Nominatim API client
      openElevation.ts # Elevation API client
      overpass.ts      # Overpass API client
      wikipedia.ts     # Wikipedia API client
      types.ts         # Place types
    supabase.ts        # Supabase client
    utils.ts           # General utilities

  views/               # Page components
    GameView.vue       # Main game page
    HomeView.vue       # Home page
    LoginView.vue      # Login page
    SignupView.vue     # Signup page
    StatisticsView.vue # Statistics page

  layouts/             # Layout components
    MapLayout.vue      # Shared map layout

  router/              # Vue Router
    index.ts           # Route definitions

  types/               # TypeScript types
    database.ts        # Generated Supabase types

  i18n/                # Internationalization
    index.ts           # i18n setup
    locales/en.ts      # English translations

  data/                # Seed data
    seedPlaces.ts      # Place seed data
    seedQuestions.ts   # Question seed data

  __tests__/           # Unit tests
    components/        # Component tests
    composables/       # Composable tests
    lib/               # Library tests
    stores/            # Store tests
    setup.ts           # Test setup

  main.ts              # App entry point
  App.vue              # Root component
  style.css            # Global styles

supabase/
  migrations/          # Database migrations
    000001_initial_schema.sql
    000002_seed_data.sql
    000003_database_functions.sql

  functions/           # Edge functions
    generate-embedding/
      index.ts         # Embedding generation

  tests/               # pgTAP tests
    test_session_first.sql
    test_match_quality.sql
    test_question_effectiveness.sql

  config.toml          # Supabase config

scripts/               # Utility scripts
  generate-places-seed.ts
  generate-questions-seed.ts

e2e/                   # Playwright E2E tests
  complete-game-flow.spec.ts
  eiffel-tower-test.spec.ts
  home.spec.ts
```

## Data Flow Patterns

### Game Flow
```
User enters description
  ↓
Frontend: Generate embedding (Edge Function)
  ↓
Frontend: Create game_session
  ↓
Database: get_candidates(session_id) - Returns top matches
  ↓
Frontend: Display candidates on map
  ↓
Database: get_next_question(session_id, match_count)
  ↓
Frontend: Display question
  ↓
User answers question
  ↓
Frontend: Insert game_answer
  ↓
Database: get_candidates(session_id) - Filtered by answer history
  ↓
Repeat until confident or max questions
  ↓
Frontend: Make guess (update game_session)
  ↓
Database: update_question_effectiveness_batch(session_id)
  ↓
Database: update_place_embedding(place_id, ...) if correct
```

### Place Addition Flow
```
User searches place name
  ↓
Frontend: Query Nominatim API
  ↓
Frontend: Display results with map preview
  ↓
User selects place
  ↓
Frontend: Extract lat, lng, descriptors
  ↓
Frontend: Generate embedding from place data
  ↓
Frontend: Insert into places table
  ↓
Database: RLS allows (authenticated user)
```

## State Management Patterns

### Singleton Composables
Used for shared state across components:

**usePlaces:**
```typescript
// Module-level state (shared)
const places = ref<Place[]>([])
const loading = ref(false)

export function usePlaces() {
  // Return shared state
  return { places, loading, fetchAllPlaces }
}
```

**Benefits:**
- Single fetch per session
- Reactive updates across components
- No prop drilling
- Prevents race conditions

### Pinia Stores
Used for complex state machines:

**game.ts:**
- Game flow state machine
- Candidate filtering
- Question history
- Answer tracking

**auth.ts:**
- Authentication state
- User session
- Login/logout logic

## Naming Conventions

**Files:**
- PascalCase for components: `QuestionCard.vue`
- camelCase for utilities: `useEmbeddings.ts`
- kebab-case for routes: `/game`, `/login`

**Variables:**
- camelCase: `topCandidates`, `userSession`
- SCREAMING_SNAKE_CASE for constants: `MAX_QUESTIONS`, `MIN_CONFIDENCE`

**Types:**
- PascalCase: `Place`, `Question`, `GameSession`
- Prefix interfaces with `I` only if needed for clarity

**Database:**
- snake_case for tables: `game_sessions`, `game_answers`
- snake_case for columns: `place_id`, `user_id`
- snake_case for functions: `get_candidates()`, `update_place_embedding()`

## Performance Optimizations

**Vector Similarity:**
- HNSW indexing on embedding columns
- Top-K limit (20 candidates max)
- Cached embeddings (no regeneration)

**Map Rendering:**
- Lazy load MapLibre (not in initial bundle)
- Cluster markers for many places
- Only render visible candidates

**Frontend:**
- Code splitting by route
- Lazy load heavy components
- Debounced API calls
- Singleton pattern for shared data

**Database:**
- RLS policies optimized
- Indexes on foreign keys
- Materialized views for stats (future)

## TypeScript Configuration

**Strict mode enabled:**
- `strict: true`
- `noUnusedLocals: true`
- `noUnusedParameters: true`
- `noImplicitReturns: true`

**Path aliases:**
- `@/` → `src/`

## Build & Deployment

**Development:**
```bash
npm run dev  # Vite dev server on localhost:5173
```

**Production:**
```bash
npm run build  # Outputs to dist/
```

**Base path:**
- `/10x-mapmaster/` (configured in vite.config.ts)

## Environment Variables

**Required:**
- `VITE_SUPABASE_URL` - Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Supabase anonymous key

**Optional (seed scripts only):**
- `VITE_SUPABASE_SERVICE_KEY` - Service role key
- `VITE_SUPABASE_FUNCTIONS_URL_PROD` - Production edge function URL
- `VITE_SUPABASE_ANON_KEY_PROD` - Production anon key
