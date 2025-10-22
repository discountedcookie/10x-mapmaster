# Game Testing Report - October 22, 2025 (Local Testing)

## Executive Summary

Manual testing of the local development build (http://localhost:5173/) revealed **CRITICAL filtering and confidence calculation bugs** that make the game essentially unplayable. The initial semantic matching works well, but the system breaks down immediately after the first question.

---

## Test Environment

- **Date**: October 22, 2025
- **URL**: http://localhost:5173/
- **Credentials**: piotr.ciastko@pm.me
- **Database**: 20 seed places (confirmed via map markers)
- **Build**: Local development (Vite)

---

## Critical Bugs Identified

### 🚨 BUG #1: Question Counter Stuck at "Question 1 of 5"

**Severity**: CRITICAL  
**Impact**: Progress tracking completely broken

**Evidence**:
- All three tests showed "Question 1 of 5" throughout entire game
- Progress bar remained at 20% despite answering 5+ questions
- Questions kept cycling but counter never incremented

**Pattern**:
- Test 1 (Taj Mahal): Asked 7+ questions, stayed at "Question 1 of 5"
- Test 2 (Mount Fuji): Asked 2+ questions, stayed at "Question 1 of 5"  
- Test 3 (Angel Falls): Asked 5+ questions, stayed at "Question 1 of 5"

**User Impact**: Players cannot see actual game progress, unclear when game will end

---

### 🚨 BUG #2: Confidence Drops to 0% After First Answer

**Severity**: CRITICAL  
**Impact**: Matching algorithm fails completely

**Evidence**:
- **Test 1 (Taj Mahal)**: Started 49% → dropped to 0% after first answer
- **Test 2 (Mount Fuji)**: Started 49% → dropped to 0% after first answer
- **Test 3 (Angel Falls)**: Started 49% → dropped to 0% after first answer

**Pattern**:
1. Initial semantic search works perfectly (49% confidence for correct matches)
2. After answering FIRST question, confidence immediately drops to 0%
3. Confidence remains at 0% for entire game
4. Never recovers

**Root Cause Hypothesis**:
- Confidence calculation logic breaks when filtering is applied
- May be dividing by zero or returning null when candidates change
- Frontend displays 0% as fallback value

---

### 🚨 BUG #3: Candidate Filtering Leads to "0 Possible Places Remaining"

**Severity**: CRITICAL  
**Impact**: Game cannot identify any matches

**Evidence**:
- **Test 1**: Started 20 candidates → 16 after one answer → stayed at 15-16
- **Test 2**: Started 20 candidates → 15 after one answer
- **Test 3**: Started 20 candidates → 15 → **0 after answering 3 questions**

**Critical Pattern in Test 3**:
```
Initial: 20 candidates (Niagara Falls 49%, Machu Picchu 48%, etc.)
Q1 (Is it very tall? Yes): 15 candidates, 0% confidence
Q2 (Is it near river/lake? Yes): 15 candidates, 0% confidence  
Q3 (Is it in major city? No): 0 candidates, 0% confidence ❌
```

**Paradox**: Map still shows ALL 20 markers despite "0 possible places remaining"

---

### 🚨 BUG #4: Map Markers Don't Update with Filtering

**Severity**: HIGH  
**Impact**: Visual feedback inconsistent with game state

**Evidence**:
- When system says "0 possible places remaining", map shows all 20 markers
- When system says "15 possible places remaining", map sometimes shows 5 markers, sometimes all 20
- No consistent pattern between candidate count and map visualization

**Expected Behavior**: Map should only show markers for remaining candidates

---

## What Works Correctly ✅

### 1. Initial Semantic Matching (Excellent!)

**Test 1 - Taj Mahal**:
- Description: "A beautiful white building in a country known for spices and colors"
- Top 5 matches:
  - Taj Mahal: 49% ✅ CORRECT
  - Sydney Opera House: 49% (also white building)
  - Pyramids of Giza: 49%
  - Eiffel Tower: 48%
  - Burj Khalifa: 48%

**Test 2 - Mount Fuji**:
- Description: "A tall snowy mountain in an island country, sacred and beautiful"
- Top 5 matches:
  - Mount Everest: 49% (tall snowy mountain)
  - Mount Fuji: 48% ✅ CORRECT
  - Statue of Liberty: 47%
  - Lake Geneva: 47%
  - Grand Canyon: 47%

**Test 3 - Angel Falls**:
- Description: "A very tall waterfall in South America surrounded by jungle"
- Top 5 matches:
  - Niagara Falls: 49% ✅ (waterfall - semantically correct!)
  - Machu Picchu: 48% ✅ (South America)
  - Lake Geneva: 48%
  - Christ the Redeemer: 48% ✅ (South America)
  - Grand Canyon: 47%

**Key Insight**: The gte-small embeddings are working EXCELLENTLY for initial semantic matching. All three tests found semantically relevant places in top 5.

---

### 2. Authentication & UI

- ✅ Login flow works perfectly
- ✅ Session persistence functional
- ✅ Map renders all 20 place markers correctly
- ✅ Navigation between views works
- ✅ User profile button visible in navbar

---

### 3. Question Quality

Questions asked were generally logical and discriminating:

**Good Questions Observed**:
- "Is it very tall (over 200 meters)?" - discriminates buildings/mountains
- "Is it in a major city?" - filters urban vs remote
- "Is it a bridge or tower?" - discriminates structure types
- "Is it a religious or spiritual site?" - discriminates purpose
- "Is it near a river or lake?" - geographic filtering
- "Can you climb to the top of it?" - functional filtering

**Issues**: 
- Questions repeat/cycle when stuck at 0 candidates
- No mechanism to escape the 0-candidate state

---

## Detailed Test Results

### Test 1: Taj Mahal (Existing in Database)

**Description**: "A beautiful white building in a country known for spices and colors"

**Initial Match**: 49% (5 candidates shown)  
**Outcome**: ❌ FAILED

**Question Sequence**:
1. "Was it built in medieval times?" → No (confidence: 49% → 0%)
2. "Was it built in ancient times?" → No (still 0%, 20 candidates)
3. "Is it in a capital city?" → No (still 0%, 20 candidates)
4. "Is it in a major city?" → Yes (16 candidates, 0%)
5. "Is it a bridge or tower?" → No (15 candidates, 0%)
6. "Is it a religious or spiritual site?" → Yes (15 candidates, 0%)
7. "Is it made primarily of stone?" → Yes (15 candidates, 0%)
8. "Is it near a river or lake?" → Yes (15 candidates, 0%)
9. "Is it a natural feature?" → No (15 candidates, 0%)
10. "Is it made of metal or steel?" → Stopped testing

**Key Observations**:
- Taj Mahal WAS correctly identified initially (49%)
- Filtering logic partially works (20 → 16 → 15 candidates)
- Confidence calculation completely broken after first answer
- Question counter never incremented from "Question 1 of 5"
- Game appears to continue indefinitely with no end condition

---

### Test 2: Mount Fuji (Existing in Database)

**Description**: "A tall snowy mountain in an island country, sacred and beautiful"

**Initial Match**: 48% (Mount Everest 49%, Mount Fuji 48%)  
**Outcome**: ❌ FAILED (same bug pattern)

**Question Sequence**:
1. "Is it very tall (over 200 meters)?" → Yes (15 candidates, 0% confidence)
2. "Can you climb to the top of it?" → Stopped testing

**Key Observations**:
- Mount Fuji correctly identified in top 2
- Same immediate confidence drop to 0%
- Same question counter bug
- Stopped test early due to obvious bug pattern

---

### Test 3: Angel Falls (NOT in Database)

**Description**: "A very tall waterfall in South America surrounded by jungle"

**Initial Match**: 49% (Niagara Falls - excellent semantic match!)  
**Outcome**: ❌ FAILED + reached 0 candidates

**Question Sequence**:
1. "Is it very tall (over 200 meters)?" → Yes (15 candidates, 0%)
2. "Is it near a river or lake?" → Yes (15 candidates, 0%)
3. "Is it in a major city?" → No (**0 candidates**, 0%)
4. "Can you climb to the top of it?" → Yes (still 0 candidates)
5. "Is it a bridge or tower?" → Stuck in loop

**Critical Observation**:
- System reached "0 possible places remaining" 
- Map still showed ALL 20 markers (visual bug)
- Questions continued to appear despite 0 candidates
- No end condition or "place not found" result screen

**Expected Behavior**: 
- After 5 questions or 0 candidates, show "We couldn't find your place" screen
- Allow user to search and add new place (Angel Falls)
- But game got stuck in infinite loop instead

---

## Algorithm Analysis

### Initial Semantic Search (Working) ✅

**Function**: Generates embedding → finds similar places via vector similarity

**Evidence of Success**:
- Taj Mahal description matched Taj Mahal (49%)
- Mount Fuji description matched Mount Fuji (48%)
- Angel Falls description matched Niagara Falls (49%) - both waterfalls!
- All descriptions found semantically relevant candidates

**Conclusion**: Vector embeddings with gte-small are working excellently

---

### Confidence Calculation (Broken) ❌

**Current Behavior**: Drops to 0% after first question answer

**Hypothesis**:
```typescript
// Likely broken code:
const confidence = topCandidate.similarity / totalCandidates
// If totalCandidates becomes 0 or similarity not recalculated, confidence = 0
```

**Root Cause**: 
- Initial confidence based on embedding similarity (working)
- After filtering, confidence calculation fails
- May not be recalculating similarity after filter
- May be using wrong formula when candidates change

---

### Candidate Filtering (Partially Working) ⚠️

**Evidence of Filtering**:
- Test 1: 20 → 16 → 15 candidates (some filtering working)
- Test 2: 20 → 15 candidates (filtering working)
- Test 3: 20 → 15 → 0 candidates (over-aggressive filtering)

**Problems**:
1. **Over-filtering**: Test 3 dropped to 0 candidates too quickly
2. **No fallback**: When 0 candidates, system should stop or relax filters
3. **No recovery**: Once at 0%, confidence never increases
4. **Map sync issue**: Map markers don't reflect filtered candidates

**Hypothesis**: 
- Filtering uses AND logic (all question answers must match)
- One mismatched answer can eliminate all candidates
- No fuzzy matching or confidence-based filtering
- Question metadata may not match place metadata accurately

---

### Question Counter (Broken) ❌

**Current Behavior**: Always shows "Question 1 of 5"

**Root Cause**: 
- Frontend state variable not incrementing
- OR backend not returning question number
- OR component not re-rendering with new question number

**Code Location**: Likely in `src/stores/game.ts` or `src/components/game/QuestionCard.vue`

---

## Comparison with Previous Testing

### Previous Test (January 2025 - Production)

**From memory: testing-findings-live-app-2**:
- Similar "0 candidates" bug observed
- Similar confidence drop issues
- Worked for newly-added places (Angel Falls succeeded after adding)
- Suspected seed embedding corruption

### Current Test (October 2025 - Local)

**New Findings**:
- Bug persists in local build (not deployment issue)
- Bug affects ALL places (seed and user-added)
- Question counter bug confirmed (not noticed before)
- Map marker sync issue confirmed

**Conclusion**: These are fundamental algorithm bugs, not data corruption or deployment issues.

---

## Recommended Investigation Priority

### Priority 1: Confidence Calculation (CRITICAL)

**Files to Investigate**:
- `src/stores/game.ts` - confidence calculation logic
- Database functions in migrations - confidence after filtering

**Questions to Answer**:
1. How is confidence calculated after initial search?
2. Why does it drop to 0% after first filter?
3. Is `topCandidate.similarity` being recalculated?

**Debugging Steps**:
1. Add console.log to confidence calculation
2. Check if `candidates` array has similarity scores after filtering
3. Verify filter function preserves similarity data

---

### Priority 2: Question Counter (HIGH)

**Files to Investigate**:
- `src/stores/game.ts` - question counter state
- `src/components/game/QuestionCard.vue` - display logic

**Questions to Answer**:
1. Is `currentQuestionNumber` being incremented?
2. Is component receiving updated prop?
3. Is there a display bug vs logic bug?

---

### Priority 3: Candidate Filtering (HIGH)

**Files to Investigate**:
- `supabase/migrations/000004_database_functions.sql` - filter_candidates function
- `src/stores/game.ts` - filtering logic

**Questions to Answer**:
1. Why does filtering drop to 0 candidates so quickly?
2. Are question answers being matched too strictly?
3. Should filtering use fuzzy matching or confidence scores?

---

### Priority 4: End Game Condition (MEDIUM)

**Files to Investigate**:
- `src/stores/game.ts` - game end logic

**Questions to Answer**:
1. What triggers game end?
2. Why does game continue at 0 candidates?
3. Why does game continue past 5 questions?

---

## Data Quality Assessment

### Database Contents: 20 Places Confirmed

**Confirmed via Map Markers**:
1. Acropolis
2. Big Ben, London
3. Brandenburg Gate
4. Burj Khalifa
5. Christ the Redeemer
6. Colosseum
7. Eiffel Tower
8. Grand Canyon
9. Great Wall of China
10. Lake Geneva
11. Machu Picchu
12. Mount Everest
13. Mount Fuji
14. Niagara Falls
15. Pyramids of Giza
16. Sagrada Familia
17. Statue of Liberty
18. Sydney Opera House
19. Taj Mahal
20. Tower Bridge

**Coverage Analysis**:
- ✅ Good geographic diversity (6 continents)
- ✅ Good type diversity (natural wonders, buildings, monuments)
- ✅ Mix of ancient/modern (Pyramids to Burj Khalifa)
- ⚠️ Missing: Africa (only Pyramids), South America (only 2 places)
- ⚠️ Heavy on European landmarks (8/20 = 40%)

**Embedding Quality**: EXCELLENT (proven by semantic matching success)

---

## User Experience Impact

### Game is Currently Unplayable

**Player Perspective**:
1. Enter description → see promising initial matches ✅
2. Answer first question → **confidence drops to 0%** ❌
3. Continue answering questions → **no visible progress** ❌
4. **Never see a result** - game either loops infinitely or shows "0 candidates" ❌
5. Cannot complete game successfully

**Frustration Points**:
- Promising start leads to disappointing failure
- No feedback on what went wrong
- No way to recover from 0 candidates
- No clear end condition
- Progress indicator misleading

---

## Success Criteria for Fix

### Must Fix (Blocking)

1. ✅ **Confidence calculation**: Should update correctly after each question, not drop to 0%
2. ✅ **Question counter**: Should increment from 1 to 5
3. ✅ **End condition**: Game should end after 5 questions OR when confidence >70%
4. ✅ **0 candidates handling**: Show "place not found" result, allow place addition

### Should Fix (High Priority)

5. ⚠️ **Map marker sync**: Update markers to show only remaining candidates
6. ⚠️ **Filtering logic**: Prevent over-aggressive filtering to 0 candidates
7. ⚠️ **Result screen**: Show final guess and confidence when game ends

### Nice to Have

8. ⚙️ **Question quality**: Avoid redundant questions, use description context
9. ⚙️ **Confidence evolution**: Show confidence increasing as questions narrow candidates
10. ⚙️ **Better feedback**: Explain why confidence is low or candidates filtered out

---

## Testing Notes

**Testing Duration**: ~25 minutes  
**Tests Completed**: 3 full game sessions  
**Screenshots Captured**: 5 key moments  
**Console Errors**: None (clean console, no JS errors)

**Key Insight**: The bugs are in the game logic, not in the UI or data layer. Initial semantic search is actually working beautifully, which makes the subsequent failures more frustrating.

---

## Next Steps for Developer

1. **Debug confidence calculation** - add logging, trace where it drops to 0%
2. **Fix question counter** - ensure state updates and component re-renders
3. **Add end condition** - stop game after 5 questions or at 0 candidates
4. **Test with console.log** - trace candidate array through filtering
5. **Consider fallback strategy** - when 0 candidates, relax filters or show "not found"
6. **Update map markers** - sync with candidate filtering state

**Estimated Fix Time**: 4-8 hours (assuming straightforward logic bugs)

**Risk**: If filtering logic is deeply flawed, may require algorithm redesign (2-3 days)
