# Known Issues and Gotchas

## Database Reset and Embeddings
After running `npx supabase db reset`, places and questions will have NULL embeddings and NULL geom fields. You must run the seed scripts to generate this data:
```bash
npm run seed:places
npm run seed:questions
```

## Question Selection Logic (UPDATED - October 22, 2025)
**Intelligent Question Filtering**: The system uses a database function `get_next_questions()` to avoid asking redundant questions. 

**How it works**:
- After each answer, the frontend calls `get_next_questions(question_history, max_questions)` 
- The database function uses PostGIS `ST_Intersects()` to check if geographic bounding boxes overlap
- If you answer YES to "Is it in Europe?", the system only shows:
  - Geographic questions whose bboxes overlap with Europe (e.g., Mediterranean, Scandinavia)
  - All semantic questions (not geography-based)
  - Skips non-overlapping continents (Asia, Africa, South America, Oceania)

**Important**: Question groups are NOT hardcoded in frontend. They're determined by the database based on `question_type` and `geographic_region` fields in the `questions` table.

## Geographic Filtering (FIXED - October 22, 2025)
**Issue**: After answering "yes" to "Is it in Europe?", the game still showed Christ the Redeemer (South America) as a candidate.

**Fix**: Updated `filter_candidates_with_history` to use PostGIS bounding box filtering instead of checking for a non-existent `continent` field. Geographic questions are defined with bounding boxes, and the function uses `ST_Within()` to check if places fall within the geographic region.

## Spatial Filtering in match_places (FIXED - October 22, 2025)  
**Issue**: The `match_places` function was returning 0 candidates even when semantic matches existed.

**Fix**: Removed the overly aggressive spatial distance filter. All semantic matches above the threshold are now returned. Spatial confidence affects the composite score but doesn't eliminate candidates.

## Environment Variables for Seed Scripts
The seed scripts require:
- `VITE_SUPABASE_URL` - Local Supabase URL
- `VITE_SUPABASE_SERVICE_KEY` - Service role key (for local DB writes)
- `VITE_SUPABASE_FUNCTIONS_URL_PROD` - Production edge function URL (for embedding generation)
- `VITE_SUPABASE_ANON_KEY_PROD` - Production anon key

## E2E Tests Disabled in CI
Playwright E2E tests pass locally but are flaky in CI. The job is commented out in `.github/workflows/ci.yml` (lines 94-147). Run locally with `npm run test:e2e`.
