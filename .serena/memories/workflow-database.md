# Workflow: Database Operations

## Migration Order

Migrations must run in sequence:
1. `000001_initial_schema.sql` - Tables, RLS policies, indexes
2. `000002_seed_data.sql` - Initial seed data (20 famous places)
3. `000003_database_functions.sql` - RPC functions, views

**Never skip migrations or run out of order.**

## Seed Workflow (CRITICAL)

After `npx supabase db reset`, places and questions will have **NULL embeddings and NULL geom fields**.

**Two-step process:**
1. **Agent resets local DB**: `npx supabase db reset` (SAFE - local only)
2. **Agent asks user to run**: `npm run seed:places && npm run seed:questions`

**Why user must run seeds:**
- Require production env variables (VITE_SUPABASE_FUNCTIONS_URL_PROD, VITE_SUPABASE_ANON_KEY_PROD)
- Call production edge function for embedding generation
- Agent must NOT run these scripts

**Verification:**
```typescript
// Agent can verify with Supabase MCP
const { data } = await supabase
  .from('places')
  .select('name, embedding')
  .limit(3)

// embedding should be vector(384), not null
```

## Supabase MCP Patterns

**Query data:**
```sql
-- Use mcp_supabase_execute_sql
SELECT name, lat, lng FROM places LIMIT 10;
```

**Schema changes:**
```sql
-- Use mcp_supabase_apply_migration
ALTER TABLE places ADD COLUMN new_field TEXT;
```

**Never use:**
- ❌ `supabase db push` (asks user first)
- ❌ Direct SQL in terminal

## Daily Reset Routine

**Local development:**
```bash
npx supabase db reset          # SAFE - resets to migration state
# Then ask user: npm run seed:places && npm run seed:questions
```

**After reset:**
- All tables recreated from migrations
- Seed data populated (20 places, no embeddings yet)
- Must run seed scripts to generate embeddings

## Database Schema Overview

**Core Tables:**
- `places` - Geographic locations with embeddings
- `questions` - Yes/no questions with embeddings
- `game_sessions` - Player game sessions
- `game_answers` - Question answers and wrong guesses

**Key Views:**
- `game_session_stats` - Computed question_count, wrong_guess_count

**Key Functions:**
- `get_candidates(session_id)` - Session-aware candidate retrieval
- `get_next_question(session_id, match_count)` - Semantic question selection
- `update_question_effectiveness_batch(session_id)` - Batch learning
- `update_place_embedding(place_id, embedding, learning_rate)` - Weighted average learning

## RLS Policies (Verified)
- ✅ `places`: SELECT (public), INSERT/UPDATE (authenticated)
- ✅ `questions`: SELECT (public), UPDATE (authenticated)
- ✅ `game_sessions`: SELECT/INSERT (user's own only)
- ✅ `game_answers`: SELECT/INSERT (user's own only)

## Environment Variables for Seed Scripts

Required:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_SUPABASE_SERVICE_KEY`

## Type Generation

After schema changes:
```bash
npm run supabase:types
```

Regenerates `src/types/database.ts` from migrations.

## Testing

**pgTAP tests:**
```bash
npm run test:db
```

**Prerequisites:**
- Local Supabase running (`npx supabase start`)
- Database reset NOT required - tests use transactions with ROLLBACK
- NO enriched seeds needed - tests create minimal data with dummy embeddings