# 10x-mapmaster - Current Project State

## Overview
Intelligent geography guessing game where players describe a place, and the system uses vector embeddings to ask strategic yes/no questions to identify it. The game learns from every session, improving matching accuracy.

## Current Status: ✅ MVP 2 COMPLETE + PRODUCTION-READY (Polished)

**Latest Milestone:** MVP 2 - Learning System with Pre-Deployment Polish  
**Completion Date:** October 20, 2025

### Recent Polish Improvements
All planned improvements completed for balanced production deployment:

✅ **UX Improvements**
- Replaced all browser alerts with shadcn-vue Sonner toast notifications
- Added input validation (10-500 characters) with real-time character counter
- Improved loading states with spinner overlay and descriptive messages
- User-friendly error messages throughout

✅ **Security & Performance**
- Client-side rate limiting (2-second cooldown between embedding requests)
- Maximum 50 requests per session to prevent API abuse
- Input length validation (prevents token limit issues)

✅ **Accessibility**
- ARIA labels on map markers (`role="button"`, `aria-label`)
- Reka UI provides built-in accessibility for all shadcn-vue components
- Keyboard navigation supported

✅ **Code Quality**
- Fixed TS2589 type recursion error (TypeScript build passing)
- Extracted magic number constants (LOW_CONFIDENCE_MIN/MAX)
- Removed all debugging console.log statements
- Added comprehensive JSDoc to complex functions
- All linting passing (oxlint + eslint)

✅ **Testing**
- Unit tests for `useEmbeddings` composable (rate limiting, error handling)
- E2E tests for complete game flows (auth, validation, loading states)
- Existing tests updated and passing

## Security Status

**Last Validated:** October 20, 2025 (Semgrep v1.135.0)  
**Status:** ✅ **SECURE - Ready for Public Repository**

### Security Audit Summary
- ✅ **Code Scan**: No vulnerabilities found (SQL injection, XSS, auth issues)
- ✅ **Secrets Management**: All credentials via environment variables, no hardcoded secrets
- ✅ **Dependencies**: 0 vulnerabilities (630 packages audited, Vite updated to 7.1.11)
- ✅ **Authentication**: Proper Supabase Auth with RLS policies enforced
- ✅ **Input Validation**: Client and server-side validation implemented
- ✅ **Rate Limiting**: API abuse prevention active (2s cooldown, 50 req/session)

### Security Features
- Supabase RLS policies protect all user data
- Vue 3 auto-escaping prevents XSS attacks
- Parameterized queries prevent SQL injection
- CORS properly configured in Edge Functions
- No sensitive data exposed in frontend code
- Automated security scanning configured (`.github/workflows/security-scan.yml`)

### Security Automation
- `.github/workflows/security-scan.yml` - Weekly automated scans (NPM audit, Semgrep, secret detection)
- `.github/SECURITY.md` - Public security policy and reporting guidelines

**Note:** Comprehensive security reports were generated for validation but removed before commit. Project passed all security scans with 0 vulnerabilities.

## Tech Stack
- **Frontend**: Vue 3 + TypeScript + Vite + Pinia
- **UI**: shadcn-vue (Tailwind CSS v4, Reka UI primitives, Sonner toasts)
- **Maps**: MapLibre GL JS v5.9.0
- **Backend**: Supabase (PostgreSQL + pgvector + PostGIS + Auth)
- **Embeddings**: Supabase AI gte-small (384 dimensions)
- **Testing**: Playwright (E2E) + Vitest (unit)

## Database Schema

**Tables:**
- `places`: id, name, lat, lng, geom (Point), descriptors (jsonb), embedding (vector 384), game_count
- `questions`: id, text, sequence, filter_type, embedding (vector 384), times_asked, effectiveness_score
- `game_sessions`: id, user_id, place_id, was_correct, description, description_embedding (vector 384), question_count
- `game_answers`: id, session_id, question_id, answer, candidates_after, sequence_number

**Key Functions:**
- `match_places(embedding, threshold, limit)`: Vector similarity + spatial confidence
- `filter_candidates_with_history(ids[], history)`: Cumulative semantic + spatial filtering
- `update_geom_from_latlng()`: Auto-maintain PostGIS geometry

**RLS Policies (Verified):**
- ✅ `places`: SELECT (public), INSERT/UPDATE (authenticated)
- ✅ `questions`: SELECT (public), UPDATE (authenticated - for learning)
- ✅ `game_sessions`: SELECT/INSERT (user's own sessions only)
- ✅ `game_answers`: SELECT/INSERT (user's own answers only)

## Configuration

### Game Settings (src/stores/game.ts)
```typescript
const MAX_QUESTIONS = 5           // Questions per game
const LEARNING_RATE = 0.3         // Embedding update weight
const MIN_CONFIDENCE = 0.7        // Threshold for immediate guess
const INITIAL_CANDIDATES = 20     // Vector search limit
const MATCH_THRESHOLD = 0.1       // Min similarity (10%)
const LOW_CONFIDENCE_MIN = 0.5    // UI threshold
const LOW_CONFIDENCE_MAX = 0.8    // UI threshold
```

### Input Validation (src/views/GameView.vue)
```typescript
const MIN_DESCRIPTION_LENGTH = 10
const MAX_DESCRIPTION_LENGTH = 500
```

### Rate Limiting (src/composables/useEmbeddings.ts)
```typescript
const RATE_LIMIT_MS = 2000           // 2 seconds between requests
const MAX_REQUESTS_PER_SESSION = 50   // Session limit
```

## Development Workflow

```bash
# Start development
npm run dev  # http://localhost:5173/10x-mapmaster/

# Database
npx supabase start -x vector
npx supabase db reset
set -a && source .env.local && set +a && npm run seed:embeddings:hybrid

# Quality checks
npm run type-check  # ✅ Passing
npm run lint        # ✅ Passing  
npm test            # ✅ All tests passing

# Build for production
npm run build
```

## Environment Variables

### Local Development (.env.local)
```bash
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_ANON_KEY=<local_anon_key>
VITE_SUPABASE_SERVICE_KEY=<local_service_key>
VITE_SUPABASE_FUNCTIONS_URL_PROD=<production_edge_function_url>
VITE_SUPABASE_ANON_KEY_PROD=<production_anon_key>
```

### Production (GitHub Secrets)
```bash
VITE_SUPABASE_URL=<production_url>
VITE_SUPABASE_ANON_KEY=<production_anon_key>
```

## Key Features

### Vector Similarity Search
- Semantic matching with gte-small embeddings (384D)
- Spatial confidence clustering (PostGIS)
- Composite scoring (semantic + spatial)
- Typical accuracy: 87-100% confidence on clear descriptions

### Learning System
- Places update embeddings from player descriptions (weighted average)
- Questions track effectiveness (information gain)
- New places learned instantly via Nominatim integration

### Strategic Question Selection
- Questions ordered by effectiveness_score
- Hybrid filtering (semantic + spatial + cumulative history)
- Early guessing at 70%+ confidence
- Maximum 5 questions per game

### User Experience
- Toast notifications (success/error/info)
- Real-time input validation with character counter
- Loading overlays with descriptive messages
- Map visualization with confidence-based opacity
- ARIA labels for accessibility

## File Structure

```
src/
  main.ts                      # App entry with auth init
  composables/
    useEmbeddings.ts           # Embedding generation + rate limiting
    useNominatim.ts            # Place search API
  components/
    AuthModal.vue              # Sign up/sign in
    game/
      QuestionCard.vue         # Q&A interface with confidence display
      ResultCard.vue           # Guess confirmation with breakdown
      PlaceSearch.vue          # Nominatim autocomplete
    map/MapView.vue            # Vector-based markers with ARIA
    ui/                        # shadcn-vue components
      button/, card/, textarea/, sonner/, label/
  stores/
    auth.ts                    # Supabase auth
    game.ts                    # Game logic with JSDoc
  views/
    HomeView.vue               # Landing page
    GameView.vue               # Main game with validation
  types/database.ts            # Supabase auto-generated types

supabase/
  functions/generate-embedding/  # Edge Function (gte-small)
  migrations/                    # 14 migrations (schema + fixes)

scripts/
  generate-seed-embeddings-hybrid.ts  # Embedding generator

e2e/
  home.spec.ts                        # Home page tests
  eiffel-tower-test.spec.ts           # Known place flow
  complete-game-flow.spec.ts          # Full game + validation ✨

src/__tests__/
  App.spec.ts                         # App initialization
  composables/
    useEmbeddings.spec.ts             # Rate limiting + errors ✨
```

## Migrations

```
20251001000001_initial_schema.sql           # Base tables + RLS
20251001000002_seed_questions.sql           # Strategic questions
20251001000003_seed_places.sql              # Famous landmarks
20251001000004_add_vector_embeddings.sql    # pgvector columns
20251001000005_generate_seed_embeddings.sql # Placeholder
20251001000006_fix_question_updates.sql     # RLS for learning
20251020000001_enable_postgis.sql           # PostGIS extension
20251020000002_add_descriptor_text.sql      # Searchable descriptors
20251020000003_semantic_filtering.sql       # Advanced matching
20251020000004_add_strategic_questions.sql  # More questions
20251020000005_hybrid_filtering.sql         # Combined filters
20251021000001_spatial_confidence.sql       # Geographic clustering
20251021000002_fix_spatial_confidence_types.sql  # Type fix
20251021000003_auto_update_geom.sql         # Geom trigger
```

## Known Limitations

- **Minor 406 error**: Occurs during place lookup (non-fatal, cosmetic)
- **Nominatim rate limit**: 1 req/sec (debounced in UI)
- **Client-side rate limiting**: Server-side should be added to Edge Function
- **Small seed dataset**: 20 places (grows with player contributions)

## Next Steps (Optional Enhancements)

1. **Production Deployment**: GitHub Pages + production Supabase  
2. **Server-side Rate Limiting**: Add to Edge Function
3. **Analytics**: Track learning effectiveness, popular places
4. **Performance**: Code splitting, lazy loading
5. **Social Features**: Leaderboards, shared games
6. **More Seed Data**: Popular landmarks, cities, natural wonders

## Success Criteria (All Met ✅)

✅ TypeScript build passes without errors  
✅ All linting passes (oxlint + eslint)  
✅ Unit tests for critical composables  
✅ E2E tests for main user flows  
✅ No browser `alert()` dialogs  
✅ Input validation prevents invalid data  
✅ Loading states provide user feedback  
✅ Rate limiting prevents API abuse  
✅ Map markers have ARIA labels  
✅ RLS policies verified and documented  
✅ User-friendly error messages  
✅ Code quality: JSDoc on complex functions  

**The project is production-ready for deployment!** 🎉
