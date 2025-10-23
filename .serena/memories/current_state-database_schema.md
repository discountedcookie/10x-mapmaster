## Database Schema

**Tables:**
- `places`: id, name, lat, lng, geom (Point), descriptors (jsonb), embedding (vector 384), game_count
- `questions`: id, text, question_type, geographic_region, embedding (vector 384), times_asked, effectiveness_score
- `game_sessions`: id, user_id, place_id (nullable), was_correct (nullable), description, description_embedding (vector 384)
- `game_answers`: id, session_id, question_id (nullable), answer, answer_type ('question_answer' | 'wrong_guess'), place_id (nullable), candidates_after (jsonb), sequence_number

**Views:**
- `game_session_stats`: Computed question_count, wrong_guess_count

**Key Functions:**
- `get_candidates(session_id)`: Session-aware with filtering
- `get_next_question(session_id, match_count)`: Semantic question selection
- `update_question_effectiveness_batch(session_id)`: Batch learning
- `update_place_embedding(place_id, embedding, learning_rate)`: Weighted average learning

**RLS Policies** (Verified):
- ✅ `places`: SELECT (public), INSERT/UPDATE (authenticated)
- ✅ `questions`: SELECT (public), UPDATE (authenticated)
- ✅ `game_sessions`: SELECT/INSERT (user's own only)
- ✅ `game_answers`: SELECT/INSERT (user's own only)
