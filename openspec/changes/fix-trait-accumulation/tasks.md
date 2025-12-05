# Tasks: Fix Trait Accumulation

## 1. Config: Update trait limit

**File**: `supabase/db/game_logic/data/config.sql`

- [ ] 1.1 Change `llm.trait_extraction.max_traits` from `20` to `30`

## 2. Config: Update prompt for knowledge curation

**File**: `supabase/db/game_logic/data/config.sql`

- [ ] 2.1 Replace `llm.trait_extraction.prompt` with new curation-focused prompt:

```
You are curating a knowledge base for a geographic guessing game.

PLACE: {place_name}
LOCATION: ({lat}, {lng}) in {country}
TYPE: {place_type}

SOURCE DATA:
{nominatim_text}

CURRENT KNOWLEDGE:
{existing_traits}

NEW INFORMATION:
User descriptions: {session_descriptions}
Confirmed facts: {game_answers}

TASK: Update the knowledge base for this place.
- Review existing traits and keep valuable ones
- Add new facts from source data or user sessions
- Remove duplicates or generic information
- Consolidate similar traits into one stronger statement
- Stay within {max_traits} traits total

TRAIT REQUIREMENTS:
- Each trait is a complete, naturally readable statement
- Include specific facts: measurements, dates, materials, architects, historical events
- Write as if explaining to a curious traveler (displayed as "What I know about this place")
- No place names, no generic adjectives like "famous" or "beautiful"
- No visitor logistics (tickets, hours, parking)

OUTPUT FORMAT (JSON):
{
  "traits": ["trait 1", "trait 2", ...],
  "changes": "Brief note about what was added/removed and why"
}
```

Note: The prompt uses `{nominatim_text}` instead of `{nominatim_json}` - this requires SQL changes in task 3.

## 3. SQL: Format nominatim as readable text

**File**: `supabase/db/game_logic/functions/places/update_place_traits.sql`

- [ ] 3.1 After filtering extratags (around line 95), build a text variable instead of JSON:
  - Format: `"category: {class}/{type}\n"` followed by each extratag as `"key: value\n"`
  - Store in new variable `v_nominatim_text`
- [ ] 3.2 Update the prompt template replacement (around line 152):
  - Change from: `replace(v_llm_prompt, '{nominatim_json}', ...)`
  - Change to: `replace(v_llm_prompt, '{nominatim_text}', COALESCE(v_nominatim_text, 'None'))`

## 4. SQL: Remove trait deletion

**File**: `supabase/db/game_logic/functions/places/update_place_traits.sql`

- [ ] 4.1 Remove line 190: `DELETE FROM place_traits WHERE place_id = p_place_id;`
- [ ] 4.2 Update the comment block at end of file to reflect new behavior (accumulate, not replace)

## 5. SQL: Parse new response format with reasoning

**File**: `supabase/db/game_logic/functions/places/update_place_traits.sql`

- [ ] 5.1 Update response parsing (around lines 171-183):
  - Extract `traits` array from response object
  - Extract `changes` field and log to NOTICE for debugging
  - Handle backward compatibility: if response is plain array, use it directly

Example parsing logic:

```sql
IF jsonb_typeof(v_traits_json) = 'object' THEN
  -- New format: {"traits": [...], "changes": "..."}
  IF v_traits_json ? 'changes' THEN
    RAISE NOTICE 'Trait changes: %', v_traits_json->>'changes';
  END IF;
  IF v_traits_json ? 'traits' THEN
    v_traits_json := v_traits_json->'traits';
  ELSE
    RAISE EXCEPTION 'Response object must have "traits" array';
  END IF;
ELSIF jsonb_typeof(v_traits_json) != 'array' THEN
  RAISE EXCEPTION 'Response must be {"traits": [...]} or an array';
END IF;
```

## 6. Manual Testing

**Script**: `scripts/test-llm-prompts.ts`

- [ ] 6.1 Test on place with existing traits:
  ```bash
  bun run scripts/test-llm-prompts.ts traits "Centennial Hall"
  ```
- [ ] 6.2 Verify:
  - Trait count grew or stayed stable (not reset)
  - Existing valuable traits preserved
  - "changes" field logged in output
  - New traits are human-readable

- [ ] 6.3 If results unsatisfactory, iterate on prompt wording or model temperature

## Verification Criteria

- [ ] Place with 15 existing traits, after update has 15-25 traits (not reset to small number)
- [ ] Valuable existing traits are preserved
- [ ] "Trait changes" logged to NOTICE
- [ ] New traits read naturally (suitable for "What I know about this place" UI)
- [ ] No exact duplicate traits in place_traits table

## Not In Scope

- Semantic deduplication (embedding similarity check) - Phase 2
- Automated tests for LLM output - not predictable enough
- Trait categorization - future work
- Edge function changes - already processes sequentially
