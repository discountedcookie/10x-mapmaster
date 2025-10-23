# Test Game Session (Zen MCP)

Comprehensive game algorithm testing with deep analysis via Zen MCP.

## Overview

Test the game algorithm by simulating a complete game session, evaluating:
- Vector similarity matching quality
- Geographic filtering accuracy
- Question selection algorithm
- Data quality and completeness
- Overall user experience flow

## Workflow

Use `mcp_zen_analyze` or `mcp_gemini_ask` with `changeMode: false` for analysis tasks.

### Step 1: Get Test Scenario

Ask the user for:
- **Place they're thinking of** (e.g., "Moscow", "Sydney Opera House", "Grand Canyon")
- **Description to test** (what they would type in the game)
- **Description embedding** (384-dim vector from frontend, or generate if needed)

If user doesn't provide embedding, you can use `mcp_gemini_ask` to generate one.

### Step 2: Create Session & Initial Analysis

```javascript
// Create test session
mcp__supabase__execute_sql({
  query: `
    INSERT INTO game_sessions (user_id, description, description_embedding, place_id, was_correct)
    VALUES ('<user_id>'::uuid, '<description>', '<embedding>'::vector(384), NULL, NULL)
    RETURNING id, description;
  `
})

// Get initial candidates
mcp__supabase__execute_sql({
  query: `
    SELECT name, lat, lng, semantic_similarity, spatial_confidence, composite_confidence,
           descriptors->>'country' as country
    FROM get_candidates('<session_id>'::uuid)
    ORDER BY composite_confidence DESC;
  `
})

// Analyze with Zen
mcp_zen_analyze({
  step: "Analyzing initial candidate matching",
  step_number: 1,
  total_steps: 5,
  next_step_required: true,
  findings: `
    Test: <place_name> - "<description>"

    Initial candidates: <N> places
    Top matches: <list top 5 with scores>

    Analysis:
    - Is the correct place present? <yes/no>
    - Semantic similarity quality: <analysis>
    - Spatial clustering behavior: <analysis>
    - Candidate diversity: <analysis>
  `,
  path: "/Users/ciaastek/Projects/Sirocco/10x-mapmaster",
  model: "gemini-2.5-pro"
})
```

### Step 3: Question Selection Analysis

```javascript
// Get question suggestions
mcp__supabase__execute_sql({
  query: `
    SELECT id, text, question_type, geographic_region->>'name' as region,
           times_asked, effectiveness_score, semantic_similarity
    FROM get_next_question('<session_id>'::uuid, 10)
    ORDER BY effectiveness_score DESC, semantic_similarity DESC
    LIMIT 10;
  `
})

// Check if semantic questions have embeddings
mcp__supabase__execute_sql({
  query: `
    SELECT text, question_type, embedding IS NOT NULL as has_embedding
    FROM questions
    WHERE question_type = 'semantic'
    LIMIT 5;
  `
})

// Analyze with Zen
mcp_zen_analyze({
  step: "Analyzing question selection algorithm",
  step_number: 2,
  total_steps: 5,
  next_step_required: true,
  findings: `
    Questions suggested: <N>
    Question types: <geographic/semantic breakdown>

    Critical checks:
    - Are semantic questions shown? <yes/no>
    - Do semantic questions have embeddings? <yes/no>
    - Question relevance to description: <analysis>
    - Question effectiveness scores: <analysis>

    Code review needed:
    - Check get_next_question() line 388 for embedding filter
    - Verify question seed data has embeddings
  `,
  path: "/Users/ciaastek/Projects/Sirocco/10x-mapmaster",
  model: "gemini-2.5-pro"
})
```

### Step 4: Simulate Question Answering

For 3-5 questions, simulate the user's answers:

```javascript
// Answer question
mcp__supabase__execute_sql({
  query: `
    INSERT INTO game_answers (session_id, question_id, answer, answer_type, sequence_number)
    VALUES ('<session_id>'::uuid, '<question_id>'::uuid, <true/false>, 'question_answer', <N>)
    RETURNING id;
  `
})

// Check updated candidates
mcp__supabase__execute_sql({
  query: `
    SELECT name, composite_confidence, descriptors
    FROM get_candidates('<session_id>'::uuid)
    ORDER BY composite_confidence DESC;
  `
})

// Analyze filtering effectiveness
mcp_zen_analyze({
  step: "Analyzing filtering after question <N>",
  step_number: <N+2>,
  total_steps: 5,
  next_step_required: true,
  findings: `
    Question: "<text>"
    Answer: <YES/NO>

    Candidates before: <N>
    Candidates after: <M>
    Reduction: <N-M> places (<percentage>%)

    Filtering analysis:
    - Was correct place retained? <yes/no>
    - Were incorrect places filtered? <analysis>
    - Filtering logic correct? <check SQL>

    Next question suggestions: <get and list>
  `,
  path: "/Users/ciaastek/Projects/Sirocco/10x-mapmaster",
  model: "gemini-2.5-pro"
})
```

### Step 5: Data Quality Analysis

```javascript
// Check descriptor completeness
mcp__supabase__execute_sql({
  query: `
    SELECT
      name,
      descriptors->>'is_capital_city' as has_capital_flag,
      descriptors->'address'->>'city' as has_city,
      descriptors->>'country_code' as has_country,
      descriptors->>'class' as has_class
    FROM places
    WHERE id IN (SELECT id FROM get_candidates('<session_id>'::uuid))
    LIMIT 10;
  `
})

// Analyze with Zen
mcp_zen_analyze({
  step: "Analyzing data quality and completeness",
  step_number: 5,
  total_steps: 5,
  next_step_required: false,
  findings: `
    Data quality issues found:

    Places:
    - Total places in DB: <N>
    - Places with embeddings: <M>
    - Missing descriptor fields: <list>

    Questions:
    - Semantic questions with embeddings: <N>/<total>
    - Geographic questions with bounding boxes: <N>/<total>

    Critical missing fields:
    - is_capital_city: <status>
    - wikipedia_summary: <status>
    - enrichment metadata: <status>

    Impact on game:
    - <analysis of how missing data affects gameplay>
    - <which semantic questions won't work>
  `,
  path: "/Users/ciaastek/Projects/Sirocco/10x-mapmaster",
  model: "gemini-2.5-pro"
})
```

### Step 6: Document Comprehensive Findings

```javascript
mcp__serena__write_memory({
  memory_name: "testing_sessions/<test_name>_<YYYYMMDD>",
  content: `# Game Session Test: <Test Name>

**Date:** <YYYY-MM-DD>
**Test Scenario:** <place> - "<description>"
**Session ID:** <uuid>
**Tester:** Zen MCP

## Executive Summary

<High-level summary of test results>

| Metric | Result | Status |
|--------|--------|--------|
| **Semantic Matching** | <X>% top match | ✅/❌ |
| **Initial Candidates** | <N> places | ✅/❌ |
| **Correct Place Ranking** | #<rank> / Not found | ✅/❌ |
| **Geographic Filtering** | <before>→<after> candidates | ✅/❌ |
| **Semantic Filtering** | Works / Broken | ✅/❌ |
| **Question Diversity** | Both types / Geo only | ✅/❌ |
| **Data Completeness** | <percentage>% | ✅/❌ |

## Detailed Findings

### ✅ What Works Well

<List strengths with evidence>

### 🚨 Critical Issues Found (P0 - Blocking)

<List blocking bugs with:>
- Problem description
- Root cause (file:line reference)
- Impact on gameplay
- Recommended fix
- Priority

### ⚠️ Data Quality Issues (P1 - High)

<List data problems with:>
- Missing fields
- Incomplete embeddings
- Coverage gaps
- Impact analysis

### 💡 Recommended Fixes (Prioritized)

#### Priority 0 (Blocking)
1. **<Issue>** - <fix>
2. **<Issue>** - <fix>

#### Priority 1 (High)
1. **<Issue>** - <fix>

#### Priority 2 (Medium)
1. **<Issue>** - <fix>

## Session Transcript

### Initial State
- **Candidates:** <N> places
- **Top 5:**
  1. <name> (<similarity>%)
  2. ...

### Question 1: "<question text>"
- **Answer:** <YES/NO>
- **Candidates after:** <M> places
- **Analysis:** <what happened>

### Question 2: "<question text>"
- **Answer:** <YES/NO>
- **Candidates after:** <K> places
- **Analysis:** <what happened>

<Continue for all questions>

## Code Analysis

### Files Reviewed
- \`supabase/migrations/000003_database_functions.sql\`
- \`scripts/generate-questions-seed.ts\`
- \`src/stores/game.ts\`

### Issues Found in Code

#### \`get_next_question()\` (Line 388)
\`\`\`sql
-- ISSUE: Filters out semantic questions without embeddings
WHERE (q.question_type != 'geographic' AND q.embedding IS NOT NULL)
\`\`\`

**Fix:** Remove embedding requirement OR generate embeddings

#### \`get_candidates()\` (Lines 228-230)
\`\`\`sql
-- ISSUE: References non-existent is_capital_city field
WHERE (ic.descriptors->>'is_capital_city')::boolean = TRUE
\`\`\`

**Fix:** Add field to place enrichment OR use alternative logic

## Database Metrics

- **Total Places:** <N>
- **Places with Embeddings:** <N> (<percentage>%)
- **Places with Geographic Data:** <N> (<percentage>%)
- **Questions (Total):** <N>
  - Geographic: <N> (<percentage>%)
  - Semantic: <N> (<percentage>%)
- **Questions with Embeddings:** <N> (<percentage>%)

## Recommendations

### Immediate Actions (Do Now)
1. <action>
2. <action>

### Short-term (This Week)
1. <action>
2. <action>

### Long-term (Product Improvements)
1. <action>
2. <action>

## Test Reproducibility

To reproduce this test:
\`\`\`sql
-- Use session ID: <uuid>
SELECT * FROM game_sessions WHERE id = '<uuid>';
SELECT * FROM game_answers WHERE session_id = '<uuid>' ORDER BY sequence_number;
\`\`\`
`
})
```

## Multi-Scenario Testing

For comprehensive analysis, test multiple scenarios:

### Scenario 1: Famous Landmark (Happy Path)
- **Place:** Eiffel Tower
- **Expected:** Should match immediately, questions refine

### Scenario 2: Missing Place (Edge Case)
- **Place:** Moscow (not in DB)
- **Expected:** Should find similar landmarks, expose data gaps

### Scenario 3: Natural Feature
- **Place:** Grand Canyon
- **Expected:** Semantic questions should distinguish from man-made

### Scenario 4: Ambiguous Description
- **Place:** "Tower in Paris"
- **Expected:** Should narrow via questions (Eiffel vs others)

## Success Criteria

✅ Semantic matching finds relevant candidates (>70% similarity)
✅ Geographic filtering reduces candidates correctly
✅ Both semantic AND geographic questions shown
✅ Semantic filtering works (or documented as broken)
✅ Questions help narrow candidates progressively
✅ Correct place remains in candidates (if in DB)
✅ All issues documented with code references
✅ Fixes prioritized by impact
✅ Memory created with actionable findings
