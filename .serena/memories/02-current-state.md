# Current State - 10x-mapmaster

## Current Status: ✅ ALGORITHMIC FILTERING COMPLETE

**Latest Milestone:** Pure algorithmic filtering implemented - all hardcoded logic removed  
**Completion Date:** October 23, 2025  
**Branch:** `main`

### What Just Changed (October 23, 2025)

**Algorithmic Filtering Refactor** - COMPLETED ✅
- Removed 40+ lines of hardcoded CASE WHEN statements
- Implemented pure pgvector + PostGIS filtering
- Geographic questions now visible (0.6 baseline score)
- Test results: 2 questions to solve Machu Picchu (15→2 candidates)
- Adding questions now requires INSERT only (no code changes)

**Core Architecture:**
1. **Phase 1:** Initial candidates via pgvector similarity (top 20)
2. **Phase 2:** Geographic filtering via PostGIS bbox intersection
3. **Phase 3:** Semantic adjustment via pgvector question similarity
4. **Phase 4:** Spatial confidence via cluster analysis

**Key Principle:** No hardcoded business logic - only pgvector + PostGIS operations

### Previous Milestone (October 22, 2025)

**AI Agent Workflow System** - Feature branch workflow with agentic reviews

**Workflow:**
1. Create branch: `git checkout -b feature/<name>`
2. Develop locally (safe to reset local DB: `npx supabase db reset`)
3. Pre-commit check: `/pre_commit_check` (lint, types, tests, security)
4. Commit with Conventional Commits: `feat(scope): description`
5. Push and create PR
6. PR review: `/review_code_changes` (comprehensive analysis)
7. Merge after approval

**Cursor Commands** (`.claude/commands/*.md`):
- `generate_feature_plan` - Complex feature planning with Zen
- `pre_commit_check` - Pre-commit quality gates (BLOCKING)
- `review_code_changes` - Full PR code review
- `analyze_security_impact` - Security review for RLS/auth changes (BLOCKING)
- `generate_db_migration` - Safe migration generation
- `refactor_component` - Component optimization

## Architecture Summary

**Tech Stack:**
- Frontend: Vue 3 + TypeScript + Vite + Pinia + Vue Router
- UI: shadcn-vue (Tailwind CSS v4, Reka UI, Sonner toasts)
- Maps: MapLibre GL JS v5.9.0
- Backend: Supabase (PostgreSQL + pgvector + PostGIS + Auth)
- Embeddings: Supabase AI gte-small (384 dimensions)
- External APIs: Open-Meteo, Overpass, Nominatim, Wikipedia
- Testing: Playwright (E2E) + Vitest (unit) + pgTAP (database)

**Data Pattern:** PostgREST (DB does work, frontend filters)  
**Vector System:** `vector(384)` with gte-small, cached embeddings  
**File Structure:** `src/{components,composables,stores,lib,types,views}`

## Active Work

**Next Planned Improvements:**

### Phase 2: Rich Embeddings (Optional - 4 hours)
- Add location context: "Eiffel Tower in Paris, capital of France"
- Add materials, age, function to embedding text
- Result: Better semantic matching without field checks

### Phase 3: Question Embeddings (Optional - 2 hours)
- Generate embeddings for geographic questions
- "Is it in Europe?" → "European architecture, cities, culture"
- Enable semantic + spatial matching for all questions

## Production Safety

**NEVER on production:**
- ❌ `supabase db reset --remote`
- ❌ `npm run seed:places` / `npm run seed:questions` (require env vars)
- ❌ Destructive operations (DROP, TRUNCATE, DELETE without WHERE)

**ALWAYS:**
- ✅ Feature branches for all work
- ✅ Local DB reset: `npx supabase db reset` (SAFE)
- ✅ Non-destructive migrations only
- ✅ RLS enabled on all tables
- ✅ Security review for schema/auth changes

## Test Status
- Database Tests: 25/25 passing ✅
- Unit Tests: 159/159 passing ✅
- Type Errors: 0 ✅
- Lint Warnings: 0 ✅
- E2E Tests: Disabled in CI (flaky), run locally only