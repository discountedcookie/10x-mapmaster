# Test Game Session

Test the game algorithm by simulating a complete game session via Supabase MCP.

## Workflow

### 1. Get Test Scenario from User

Ask the user for:
- **Place they're thinking of** (e.g., "Eiffel Tower")
- **Game session id** (e.g., "6a9eed4b-bfda-4977-93a2-75349a253ec8")

### 2. Query Initial Candidates

```javascript
mcp__supabase__execute_sql({
  query: `
    SELECT
      name,
      lat,
      lng,
      semantic_similarity,
      spatial_confidence,
      composite_confidence,
      descriptors->>'country' as country,
      descriptors->>'display_name' as display_name
    FROM get_candidates('<session_id>'::uuid)
    ORDER BY composite_confidence DESC;
  `
})
```

**Analyze:**
- How many candidates returned?
- Is the correct place in top 5? Top 10? Not present?
- What are the semantic similarity scores?
- Are spatial confidence scores reasonable?

### 3. Get Question Suggestions

```javascript
mcp__supabase__execute_sql({
  query: `
    SELECT
      id,
      text,
      question_type,
      geographic_region->>'name' as region_name,
      times_asked,
      effectiveness_score,
      semantic_similarity
    FROM get_next_question('<session_id>'::uuid, 10)
    ORDER BY
      effectiveness_score DESC,
      semantic_similarity DESC,
      times_asked ASC
    LIMIT 10;
  `
})
```

**Analyze:**
- What question types are suggested? (Geographic vs Semantic)
- Are semantic questions appearing? (Check if they have embeddings)
- Are questions relevant to the description?

### 4. Simulate Answering Questions

For each suggested question, simulate an answer based on the actual place:

```javascript
mcp__supabase__execute_sql({
  query: `
    INSERT INTO game_answers (
      session_id,
      question_id,
      answer,
      answer_type,
      sequence_number
    )
    VALUES (
      '<session_id>'::uuid,
      '<question_id>'::uuid,
      <true_or_false>,
      'question_answer',
      <sequence_number>
    )
    RETURNING id, answer, sequence_number;
  `
})
```

After each answer:
- Re-query candidates using `get_candidates()`
- Check how many candidates remain
- Verify the correct place is still in the list
- Get next question suggestions

**Repeat 3-5 times** (max questions per session)

### 5. Evaluate Algorithm Performance

Document:

#### Semantic Matching
- ✅/❌ Initial candidate ranking quality
- ✅/❌ Correct place in initial candidates
- Similarity scores for top matches

#### Geographic Filtering
- ✅/❌ Candidates properly filtered after geographic questions
- Before/after counts
- ✅/❌ Correct place retained

#### Question Quality
- ✅/❌ Semantic questions shown (or only geographic?)
- ✅/❌ Questions relevant to description
- ✅/❌ Questions help narrow candidates effectively

#### Data Quality Issues
- Missing embeddings (questions or places)
- Missing descriptor fields (is_capital_city, etc.)
- Places not in database

### 6. Document Findings

Save findings to Serena memory:

```javascript
mcp__serena__write_memory({
  memory_name: "testing_sessions/<test_name>_<date>",
  content: `# Game Session Test: <Test Name>

**Date:** <YYYY-MM-DD>
**Test Scenario:** <place> - "<description>"

## Results Summary

| Metric | Result | Status |
|--------|--------|--------|
| Semantic Matching | <X>% similarity | ✅/❌ |
| Initial Candidates | <N> places | ✅/❌ |
| Correct Place Ranking | #<rank> / Not found | ✅/❌ |
| Geographic Filtering | <before>→<after> | ✅/❌ |
| Question Diversity | Geographic only / Mixed | ✅/❌ |
| Semantic Filtering | Works / Broken | ✅/❌ |

## Detailed Findings

### What Works Well
<list what worked>

### Critical Issues Found
<list blocking issues>

### Data Quality Issues
<list missing data>

### Recommendations
<prioritized fix list>

## Session Data

**Session ID:** <uuid>
**Initial Candidates:** <N>
**Questions Asked:** <N>
**Final Candidates:** <N>

### Question Flow
1. Q: "<question>" → A: YES/NO → Candidates: <N>
2. Q: "<question>" → A: YES/NO → Candidates: <N>
...
`
})
```

## Common Test Scenarios

### Test Famous Landmarks
- "Sydney" - "iconic opera house by the harbor..."
- "Machu Picchu" - "ancient Incan city in the mountains..."

### Test Natural Features
- "Grand Canyon" - "massive gorge carved by a river..."
- "Mount Everest" - "tallest mountain in the world..."

### Test Edge Cases
- Place not in database (test candidate quality)
- Vague description (test semantic matching robustness)
- Multiple possible matches (test disambiguation)

## Success Criteria

✅ Semantic matching finds relevant candidates (>70% similarity)
✅ Geographic filtering works correctly
✅ Both semantic AND geographic questions shown
✅ Candidates narrow after each question
✅ Correct place remains in candidates throughout
✅ No crashes or SQL errors
