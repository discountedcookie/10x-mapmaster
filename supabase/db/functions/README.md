# PostgreSQL Functions

This directory contains all PostgreSQL functions organized by category. Each function is extracted from the migration files and represents the latest version.

## Directory Structure

```
functions/
├── game/                    # Core game mechanics
├── questions/              # Question pool management
├── places/                 # Place enrichment and matching
├── maintenance/            # Cleanup and maintenance jobs
└── utilities/              # Helper functions and triggers
```

## Game Functions (5)

### Core Game Loop

- **`play_turn(session_id, answer, question_metadata)`** - State machine for game turns
  - Handles question answers and guess confirmations
  - Updates semantic constraints or geographic filters
  - Records answers and recalculates candidates
  - Enforces 5-turn limit
  - Returns next action (question, guess, or game end)

- **`start_game(p_description, p_language_code)`** - Initialize game session
  - Generates embedding server-side
  - Finds initial candidates
  - Sets up first question or guess
  - Returns complete game state

### Candidate Management

- **`get_candidates(session_id)`** - Retrieve ranked candidates
  - Applies semantic similarity filtering
  - Applies geographic filters from session answers
  - Calculates confidence gap between top 2 candidates
  - Excludes previously wrong-guessed places
  - Returns candidates with composite confidence scores

- **`get_last_turn_type(session_id)`** - Determine previous turn type
  - Returns 'question', 'guess', or 'initial'
  - Used for turn validation

### Semantic Constraint Management

- **`update_semantic_constraint(session_id, question_type, answer, trait)`** - Update semantic constraint
  - Maintains affirmed/denied trait lists (capped at 6 each)
  - Regenerates description embedding (CRITICAL for candidate narrowing)
  - Format: "Original description. Affirmed: trait1; trait2. Denied: traitA; traitB."
  - Called after semantic question answers

## Question Functions (4)

- **`generate_question(description, candidates, previous_qa, available_questions, threshold)`** - LLM-based question generation
  - Selects or generates next question
  - Validates output for injection/jailbreak patterns
  - Returns question_id and metadata

- **`get_next_question(session_id, limit)`** - Retrieve available questions
  - Excludes previously asked questions
  - Orders by effectiveness score
  - Returns top N questions

- **`update_question_effectiveness_batch(session_id)`** - Update question scores after session
  - Calculates precision gain: (candidates_before - candidates_after) / candidates_before
  - Applies survival bonus: +1 if correct place survived, -1 if eliminated
  - Applies effectiveness bonus: +0.01 for splits >= 30% that kept truth
  - Applies penalty: -0.02 for weak questions (splits < 5%)

- **`deduplicate_questions()`** - Remove duplicate questions
  - Triggered periodically
  - Keeps highest effectiveness score version

## Place Functions (5)

- **`add_place(name, lat, lng, language_code, canonical_description, semantic_constraint, nominatim_place_id)`** - Add new place
  - Generates embedding server-side
  - Validates coordinates and inputs
  - Marks as pending_review
  - Returns place_id

- **`match_places(embedding, constraint, geographic_filters, threshold, limit)`** - Semantic + geographic matching
  - Calculates semantic similarity (cosine distance)
  - Applies geographic filters (include/exclude bounding boxes)
  - Calculates composite confidence score
  - Returns top N matches

- **`approve_pending_place(place_id)`** - Approve user-submitted place
  - Marks pending_review = false
  - Triggers enrichment

- **`enrich_place(place_id)`** - Consolidate place description
  - Collects all completed sessions for place
  - Calls LLM to consolidate descriptions
  - Regenerates embedding
  - Builds descriptors from Q&A data
  - Updates place with enriched data

- **`deduplicate_places()`** - Remove duplicate places
  - Triggered periodically
  - Keeps highest times_encountered version

## Maintenance Functions (3)

- **`maintenance_cleanup()`** - Daily cleanup job
  - Deletes sessions older than 24 hours
  - Runs via pg_cron daily

- **`maintenance_weekly()`** - Weekly maintenance
  - Prunes question pool (keeps top 450 by effectiveness)
  - Deduplicates questions and places
  - Runs via pg_cron weekly

- **`touch_session_last_activity()`** - Update session timestamp
  - Called on every game action
  - Prevents premature session expiration

## Utility Functions (7)

### Embedding & LLM

- **`generate_embedding(text)`** - Generate vector embedding
  - Uses configured LLM provider (via app.llm_provider setting)
  - Returns vector(1024) for all embeddings
  - Server-side only (never client-side)

- **`call_llm_api(prompt, max_tokens)`** - Call LLM API
  - Used for question generation and place enrichment
  - Handles provider configuration

### Input Validation

- **`validate_user_input(text, max_length, field_name)`** - Validate user input
  - Checks length constraints
  - Detects injection patterns
  - Raises exceptions for invalid input

- **`apply_metadata_filter(metadata, filter_type)`** - Apply metadata filters
  - Filters candidates by metadata criteria
  - Used in question generation

### Session Management

- **`approve_pending_session()`** - Trigger on session approval
  - Called when admin approves session
  - Triggers place enrichment

### Place Enrichment Triggers

- **`enrich_place_on_approval()`** - Trigger on place approval
  - Called when place is approved
  - Calls enrich_place()

- **`enrich_place_on_session_complete()`** - Trigger on session completion
  - Called when game session ends
  - Calls enrich_place() for the guessed place

- **`update_place_embedding(place_id)`** - Regenerate place embedding
  - Called when place description changes
  - Regenerates vector embedding

## Key Patterns

### Database-First Architecture

All game logic lives in PostgreSQL functions. Frontend only:

- Displays results
- Handles user interaction
- Sends answers to play_turn()

### Idempotency

All functions are idempotent:

- Can be called multiple times safely
- Use CREATE OR REPLACE FUNCTION
- Handle NULL inputs gracefully

### Security

- SECURITY DEFINER for sensitive operations
- RLS policies on all tables
- Input validation on all user-facing functions
- Parameterized queries (no string concatenation)

### Performance

- pgvector HNSW indexes for embedding similarity
- PostGIS indexes for geographic queries
- Efficient candidate ranking with confidence gap calculation
- Question pool pruning to keep top 450 by effectiveness

## Dependencies

### Vector Embeddings

- All embeddings use vector(1024) dimension
- Generated by generate_embedding() function
- Cosine similarity for matching
- HNSW indexes for fast search

### Geographic Filtering

- PostGIS for spatial queries
- SRID 4326 (WGS84) for all geometries
- ST_Distance for accurate distance calculations
- Bounding box filters for geographic questions

### LLM Integration

- Configurable provider via app.llm_provider setting
- Used for question generation and place enrichment
- Fallback mechanisms for API failures

## Testing

All functions have pgTAP tests in `supabase/tests/`:

- Cold start scenarios
- Candidate ranking
- Semantic constraint updates
- Question effectiveness scoring
- RLS policies
- Session lifecycle

## Migration History

Functions are extracted from migrations numbered 000001-000080. Each function's latest version is documented in its SQL file header.

## Usage

To apply all functions to a database:

```bash
# Apply all migrations (includes functions)
supabase db reset

# Or apply specific function
psql -f supabase/db/functions/game/play_turn.sql
```

To test functions:

```bash
supabase test db
```
