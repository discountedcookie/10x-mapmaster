# Known Issues and Gotchas

## Active Issues

### Minor 406 Error During Place Lookup ⚠️ (LOW PRIORITY)

**Status**: Cosmetic issue, non-blocking

**Symptoms**:
- Console shows 406 (Not Acceptable) error during `checkPlaceExists` query
- Place saving completes successfully despite error
- User experience unaffected

**Root Cause** (suspected): PostgREST accept header mismatch or RLS policy evaluation quirk

**Impact**: Purely cosmetic console error

---

### Nominatim Rate Limiting ✅ (ACCEPTABLE FOR MVP)

**Note**: OpenStreetMap Nominatim API has 1 request/second rate limit.

**Current Implementation**: 
- PlaceSearch component debounces input (500ms)
- Works well for manual typing
- Client respects rate limits

**Status**: Acceptable for MVP

---

### Client-Side Only Rate Limiting ⚠️ (PRODUCTION TODO)

**Current State**: Rate limiting implemented client-side only (2s cooldown, 50 requests/session)

**Risk**: Determined users could bypass by:
- Opening multiple tabs
- Clearing browser storage
- Using developer tools

**Recommendation**: Add server-side rate limiting to Edge Function before production deployment.

**Implementation**: 
- Track requests by IP or user ID
- Return 429 status when limit exceeded
- Client already handles 429 gracefully

---

## Resolved Issues (Fixed)

### ✅ TypeScript TS2589 Type Recursion (FIXED)

**Issue**: `Type instantiation is excessively deep and possibly infinite` in game.ts

**Cause**: Supabase `Json` type recursion when TypeScript infers complex array types

**Fix**: 
- Changed `ref<PlaceWithScore[]>([])` to `ref([] as PlaceWithScore[])`
- Changed `ref<Array<{ ... }>>([])` to `ref([] as Array<{ ... }>)`
- Used manual loop instead of `.map()` to avoid type inference

**Files**: src/stores/game.ts

---

### ✅ PostgreSQL Type Mismatch in Spatial Confidence (FIXED)

**Issue**: SQL error 42804 - `numeric` vs `double precision` mismatch

**Fix**: Migration `20251021000002_fix_spatial_confidence_types.sql` - cast all arithmetic to `::double precision`

---

### ✅ Missing PostGIS Geometry Auto-Population (FIXED)

**Issue**: New places saved without `geom`, excluded from searches

**Fix**: Migration `20251021000003_auto_update_geom.sql` - trigger auto-syncs geom with lat/lng

---

### ✅ Learning System RLS Policies (FIXED)

**Issue**: 406/400 errors when updating questions table

**Fix**: Migration `20251001000006_fix_question_updates.sql` - added UPDATE policy for authenticated users

---

## Gotchas

### Database Reset Removes Auth Users

**Behavior**: `npx supabase db reset` clears ALL data including auth.users

**Solution**: 
- Sign out after reset: `authStore.signOut()`  
- Or clear storage: `localStorage.clear()`
- Or create new test account

---

### Seed Embeddings After Reset

**Required**: After `npx supabase db reset`, run embedding generation:

```bash
set -a && source .env.local && set +a && npm run seed:embeddings:hybrid
```

**Why**: Migration 20251001000005 is just a placeholder
