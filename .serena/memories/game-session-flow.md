# Game Session Flow Architecture

## Session-Centric Design (October 22, 2025)

The game uses a **session-first** architecture where the `game_sessions` record is created at the START of the game, not at the end. This allows the database to maintain full context.

## New Game Flow

### 1. Start Game
```typescript
async function startNewGame(description: string) {
  // Generate embedding
  const embedding = await generateEmbedding(description)
  
  // Create session IMMEDIATELY
  const { data: session } = await supabase
    .from('game_sessions')
    .insert({
      user_id: authStore.user.id,
      description: description,
      description_embedding: embeddingToString(embedding),
      place_id: null,  // Will be set at the end
      was_correct: null, // Will be set at the end
      question_count: 0
    })
    .select()
    .single()
  
  gameSessionId.value = session.id
  
  // Find candidates
  await findCandidatesByEmbedding(embedding)
  
  // Load questions using session context
  await loadQuestionsForSession()
}
```

### 2. Load Questions (Initial and After Each Answer)
```typescript
async function loadQuestionsForSession() {
  const { data } = await supabase.rpc('get_next_question', {
    session_id_param: gameSessionId.value,
    match_count: MAX_QUESTIONS
  })
  
  questions.value = data || []
  currentQuestionIndex.value = 0
}
```

### 3. Answer Question
```typescript
async function answerQuestion(answer: boolean) {
  // Refine candidates
  await refineCandidates(answer)
  
  // Save answer to database IMMEDIATELY
  await supabase
    .from('game_answers')
    .insert({
      session_id: gameSessionId.value,
      question_id: currentQuestion.value.id,
      answer: answer,
      candidates_after: candidates.value.length,
      sequence_number: answers.value.length + 1
    })
  
  // Reload questions with updated session context
  await loadQuestionsForSession()
}
```

### 4. End Game
```typescript
async function endGame(actualPlace: Place, wasCorrect: boolean) {
  // Just update the session with final results
  await supabase
    .from('game_sessions')
    .update({
      place_id: actualPlace.id,
      was_correct: wasCorrect,
      question_count: answers.value.length
    })
    .eq('id', gameSessionId.value)
}
```

## Database Function

### `get_next_question(session_id, limit)`
**Single unified function** that:
1. Queries `game_sessions` for `description_embedding`
2. Queries `game_answers` for answer history
3. Returns questions filtered by:
   - Already answered questions (excluded)
   - Geographic bbox logic (if answered YES to geographic question)
   - Semantic similarity to description
   - Effectiveness score

## Benefits

1. **Stateful**: Database maintains full game context
2. **Simple**: One function for all question selection
3. **Consistent**: Questions always reflect current session state
4. **Recoverable**: Session exists from start, could resume games
5. **Analytics**: Can analyze in-progress games, not just completed ones

## RLS Considerations

Since sessions are created upfront, ensure RLS policies allow:
- INSERT: User can create their own sessions
- UPDATE: User can update their own sessions
- SELECT: User can read their own sessions

`game_answers` needs:
- INSERT: User can insert answers for their own sessions
- SELECT: User can read answers for their own sessions
