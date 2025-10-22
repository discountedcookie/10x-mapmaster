# Session-Centric Game Architecture Refactor (October 22, 2025)

## What Changed

Refactored from **end-of-game session creation** to **session-first architecture** where the database maintains full game context.

## Key Changes

### 1. Database Schema (`000001_initial_schema.sql`)
**Changed `game_sessions` table**:
- `place_id`: `NOT NULL` → `NULL` (set at game end)
- `was_correct`: `NOT NULL` → `NULL` (set at game end)

### 2. Database Functions (`000003_database_functions.sql`)

**Removed**:
- `match_questions()` - Old vector similarity search for questions

**Added**:
- `get_next_question(session_id, limit)` - **Single unified function** that:
  - Queries `game_sessions` to get `description_embedding`
  - Queries `game_answers` to get answer history for this session
  - Returns questions filtered by:
    - Already answered in this session (excluded)
    - Geographic bbox overlap (if YES to geographic question)
    - Semantic similarity to description
    - Effectiveness score

**Updated**:
- `match_places()` - Removed overly aggressive spatial filtering
- `filter_candidates_with_history()` - Now uses PostGIS bbox filtering instead of non-existent continent field

### 3. Frontend (`src/stores/game.ts`)

**New State**:
```typescript
const gameSessionId = ref<string | null>(null)
```

**Game Flow**:
1. `startNewGame()` - Creates session immediately, then loads questions
2. `answerQuestion()` - Saves answer to DB, reloads questions from DB
3. `finalizeGameSession()` - Updates session with final place_id and was_correct

**Renamed/Replaced**:
- `loadQuestions()` → `loadQuestionsForSession()` - Uses `get_next_question(session_id)`
- `saveGameSession()` → `finalizeGameSession()` - Updates existing session instead of creating new one
- Removed `incrementQuestionAsked()` - No longer needed, answers saved to DB directly
- Removed `reloadNonRedundantQuestions()` - Replaced with `loadQuestionsForSession()`

### 4. Frontend (`src/views/GameView.vue`)
- Updated calls from `saveGameSession()` to `finalizeGameSession()`

## Benefits

1. **Stateful**: Database maintains full game context
2. **Simple**: One RPC call for question matching
3. **No hardcoded logic**: Question groups/filtering defined by DB schema
4. **Extensible**: Add new question types by updating DB, no frontend changes
5. **Recoverable**: Could pause/resume games (session exists from start)
6. **Analytics-ready**: Can analyze in-progress games

## How It Works

### Initial Question Load (Empty Session)
```sql
get_next_question(session_id) 
-- Returns: All geographic questions + semantic questions ranked by similarity
```

### After Answering "YES" to "Is it in Europe?"
```sql
get_next_question(session_id)
-- Database queries game_answers, finds "Is it in Europe?" = YES
-- Returns: Only European-overlapping geographic questions + semantic questions
-- Skips: Asia, Africa, South America, Oceania, North America
```

### After Answering Multiple Questions
```sql
get_next_question(session_id)
-- Excludes: All previously answered questions
-- Filters: Based on all geographic YES answers (bbox intersections)
-- Ranks: By effectiveness score and semantic similarity
```

## Testing Status

✅ Database function tested - correctly filters Christ the Redeemer when Europe=YES
✅ TypeScript types regenerated - schema changes reflected
✅ Linting passes for game.ts
⚠️ Integration testing needed - try playing a full game session
