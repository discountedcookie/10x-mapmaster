# Diagnostics: Solutions & Debugging Patterns

## Debugging Database Issues

### Check RLS Policies
```sql
-- View all RLS policies
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public';

-- Test RLS as specific user
SET request.jwt.claim.sub = '<user-id>';
SELECT * FROM game_sessions; -- Should only see own sessions
```

### Verify Embeddings Exist
```sql
-- Check for NULL embeddings
SELECT COUNT(*) as null_embeddings
FROM places
WHERE embedding IS NULL;

-- Check embedding dimensions
SELECT name, array_length(embedding::float[], 1) as dims
FROM places
LIMIT 5;
-- Should all be 384
```

### Test Vector Similarity
```sql
-- Check similarity distribution
SELECT 
  MIN(p1.embedding <=> p2.embedding) as min_distance,
  AVG(p1.embedding <=> p2.embedding) as avg_distance,
  MAX(p1.embedding <=> p2.embedding) as max_distance
FROM places p1, places p2
WHERE p1.id < p2.id
LIMIT 1000;

-- Good distribution: min 0.0-0.2, avg 0.5-0.7, max 0.8-1.0
-- Bad distribution: all in 0.6-0.8 range (embeddings too similar)
```

### Debug Candidate Filtering
```sql
-- Manually test get_candidates function
SELECT * FROM get_candidates('<session-id>');

-- Check what questions were answered
SELECT 
  q.text,
  ga.answer,
  ga.sequence_number
FROM game_answers ga
JOIN questions q ON q.id = ga.question_id
WHERE ga.session_id = '<session-id>'
  AND ga.answer_type = 'question_answer'
ORDER BY ga.sequence_number;

-- Check wrong guesses
SELECT 
  p.name,
  ga.sequence_number
FROM game_answers ga
JOIN places p ON p.id = ga.place_id
WHERE ga.session_id = '<session-id>'
  AND ga.answer_type = 'wrong_guess'
ORDER BY ga.sequence_number;
```

### Inspect PostGIS Geometries
```sql
-- View question bboxes
SELECT 
  text,
  ST_AsText(bbox) as bbox_wkt,
  ST_Area(bbox::geography) / 1000000 as area_km2
FROM questions
WHERE question_type = 'geographic';

-- Check if place is within bbox
SELECT 
  p.name,
  ST_Within(p.geom, q.bbox) as is_within
FROM places p
CROSS JOIN questions q
WHERE q.text = 'Is it in Europe?'
LIMIT 10;
```

---

## Debugging Frontend Issues

### Check Supabase Connection
```typescript
// In browser console
const { data, error } = await supabase.from('places').select('count')
console.log('Places count:', data, error)
```

### Inspect Game State
```typescript
// In Vue DevTools or browser console
import { useGameStore } from '@/stores/game'
const gameStore = useGameStore()

console.log('Current session:', gameStore.currentSession)
console.log('Top candidates:', gameStore.topCandidates)
console.log('Question history:', gameStore.questionHistory)
console.log('Top confidence:', gameStore.topConfidence)
```

### Debug Embedding Generation
```typescript
// Test embedding generation
import { generateEmbedding } from '@/composables/useEmbeddings'

const embedding = await generateEmbedding('Eiffel Tower')
console.log('Embedding dimensions:', embedding.length) // Should be 384
console.log('Sample values:', embedding.slice(0, 10))
```

### Check MapLibre Issues
```typescript
// In browser console, after map loads
console.log('Map loaded:', map)
console.log('Map style:', map.getStyle())
console.log('Map sources:', Object.keys(map.getStyle().sources))
console.log('Map layers:', map.getStyle().layers.map(l => l.id))
```

---

## Testing Strategies

### Unit Test Patterns

**Supabase Mocking:**
```typescript
import { vi } from 'vitest'

// Mock Supabase client
const mockSupabase = {
  from: vi.fn(() => ({
    select: vi.fn(() => ({
      eq: vi.fn(() => Promise.resolve({ data: [], error: null }))
    }))
  }))
}

// Use in test
vi.mock('@/lib/supabase', () => ({ supabase: mockSupabase }))
```

**Component Testing:**
```typescript
import { mount } from '@vue/test-utils'
import { createPinia } from 'pinia'

describe('QuestionCard', () => {
  it('should display question text', () => {
    const wrapper = mount(QuestionCard, {
      props: { question: { text: 'Is it tall?' } },
      global: {
        plugins: [createPinia()]
      }
    })
    
    expect(wrapper.text()).toContain('Is it tall?')
  })
})
```

### Database Test Patterns

**Self-Contained Tests:**
```sql
BEGIN; -- Transaction

-- Create test helper
CREATE OR REPLACE FUNCTION test_dummy_embedding(pattern_id int DEFAULT 1)
RETURNS vector(384) AS $$
  -- ... implementation
$$ LANGUAGE sql;

-- Create test data
CREATE TEMP TABLE test_data (
  user_id uuid,
  session_id uuid,
  place1_id uuid,
  place2_id uuid
);

INSERT INTO test_data (user_id)
SELECT id FROM auth.users LIMIT 1;

-- Run tests
SELECT ok(
  (SELECT COUNT(*) FROM get_candidates(session_id)) = 3,
  'Should return 3 candidates'
);

ROLLBACK; -- Clean up
```

**Testing RPC Functions:**
```sql
-- Test function return type
SELECT has_function('get_candidates', 'Should have get_candidates function');

-- Test function signature
SELECT function_returns(
  'get_candidates',
  ARRAY['uuid'],
  'TABLE(id uuid, name text, ...)',
  'get_candidates should return table'
);

-- Test function behavior
SELECT is(
  (SELECT COUNT(*) FROM get_candidates('<session-id>'))::int,
  5,
  'Should return 5 candidates'
);
```

---

## Common Error Messages & Solutions

### "No plan found in TAP output"
**Meaning:** pgTAP test file doesn't follow TAP format perfectly.

**Impact:** Cosmetic only - tests still validate correctly.

**Solution:** Add TAP plan at start of test file:
```sql
SELECT plan(8); -- Number of tests
-- ... tests
SELECT * FROM finish();
```

### "Type instantiation is excessively deep"
**Meaning:** TypeScript recursive type resolution limit reached.

**Solution:** Use `toRaw()` to strip Vue reactivity:
```typescript
import { toRaw } from 'vue'
const plainData = toRaw(reactiveData.value)
```

### "function min(uuid) does not exist"
**Meaning:** PostgreSQL doesn't have aggregate functions for UUID type.

**Solution:** Use separate queries or convert to text:
```sql
SELECT MIN(id::text)::uuid FROM table_name;
```

### "Cannot read property of null"
**Meaning:** Accessing property on null/undefined value.

**Solution:** Use optional chaining:
```typescript
const value = object?.property?.subproperty ?? 'default'
```

### "RETURNING INTO invalid in this context"
**Meaning:** pgTAP doesn't support RETURNING INTO syntax.

**Solution:** Use CTE pattern (see diagnostics-known-issues.md).

---

## Performance Debugging

### Check Query Execution Plans
```sql
EXPLAIN ANALYZE
SELECT * FROM get_candidates('<session-id>');

-- Look for:
-- - Sequential scans (bad, should use indexes)
-- - Index scans (good)
-- - High execution time
```

### Monitor Vector Similarity Performance
```sql
-- Check HNSW index usage
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM places
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector(384)
LIMIT 20;

-- Should show "Index Scan using idx_places_embedding"
```

### Profile Frontend Performance
```typescript
// Use Vue DevTools Performance tab
// Or browser Performance API
performance.mark('start-fetch')
await fetchCandidates()
performance.mark('end-fetch')
performance.measure('fetch-duration', 'start-fetch', 'end-fetch')
console.log(performance.getEntriesByName('fetch-duration')[0].duration)
```

---

## Network Debugging

### Check API Requests
```typescript
// Enable Supabase debug logging
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(url, key, {
  auth: {
    debug: true // Logs all auth operations
  }
})
```

### Monitor Edge Function Calls
```typescript
// Check edge function response
const { data, error } = await supabase.functions.invoke('generate-embedding', {
  body: { text: 'Test' }
})

console.log('Response:', data)
console.log('Error:', error)
console.log('Headers:', error?.context?.headers)
```

### Debug Rate Limiting
```typescript
// Check rate limit headers (if implemented)
const response = await fetch('/api/endpoint')
console.log('Rate limit remaining:', response.headers.get('X-RateLimit-Remaining'))
console.log('Rate limit reset:', response.headers.get('X-RateLimit-Reset'))
```

---

## Migration Debugging

### Check Migration Status
```bash
# List applied migrations
npx supabase migration list

# Show migration diff
npx supabase db diff

# Validate migrations
npx supabase db lint
```

### Roll Back Migration
```bash
# Local only (destructive)
npx supabase db reset

# Production: Create reverse migration
# DO NOT use db reset on production
```

### Test Migration Locally
```bash
# Reset to clean state
npx supabase db reset

# Apply migrations one by one
npx supabase migration up

# Check for errors
npx supabase status
```

---

## Debugging Checklist

### When Game Flow Breaks
- [ ] Check browser console for JavaScript errors
- [ ] Verify Supabase connection (auth token valid?)
- [ ] Inspect game store state (current session exists?)
- [ ] Check database for session record
- [ ] Verify embeddings are not NULL
- [ ] Test get_candidates() function manually
- [ ] Check RLS policies (can user access data?)

### When Tests Fail
- [ ] Run `npm run type-check` - TypeScript errors?
- [ ] Run `npm run lint` - Linting errors?
- [ ] Check test data - using dummy embeddings correctly?
- [ ] Verify database is running (`npx supabase status`)
- [ ] Check for transaction conflicts (tests using ROLLBACK?)
- [ ] Look for async timing issues (missing `await`?)

### When Embeddings Don't Match
- [ ] Verify embedding dimensions (384)
- [ ] Check embedding text input (rich enough?)
- [ ] Test cosine similarity distribution
- [ ] Inspect edge function logs
- [ ] Verify HNSW index exists
- [ ] Check for NULL embeddings

### When Map Doesn't Display
- [ ] Check MapLibre GL JS loaded
- [ ] Verify map style URL accessible
- [ ] Check candidate data has lat/lng
- [ ] Inspect GeoJSON source data
- [ ] Verify map container has dimensions
- [ ] Check for theme-related map recreation

---

## Useful SQL Queries

### Find Duplicate Places
```sql
SELECT name, lat, lng, COUNT(*)
FROM places
GROUP BY name, lat, lng
HAVING COUNT(*) > 1;
```

### Check Database Sizes
```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Find Slow Queries
```sql
SELECT 
  query,
  calls,
  total_time,
  mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

### Analyze Table Statistics
```sql
ANALYZE places;
ANALYZE questions;

SELECT * FROM pg_stats
WHERE tablename IN ('places', 'questions');
```

---

## Quick Fixes Reference

| Problem | Quick Fix |
|---------|-----------|
| NULL embeddings | Run `npm run seed:places` (user only) |
| Type errors | Run `npm run supabase:types` |
| Test failures | Check dummy embedding patterns |
| Map not showing | Verify candidates have lat/lng |
| RLS blocking queries | Check `auth.uid()` matches user_id |
| Slow vector search | Verify HNSW index exists |
| Theme not switching | Check localStorage 'theme-preference' |
| Session lost on refresh | Database-first - check session in DB |