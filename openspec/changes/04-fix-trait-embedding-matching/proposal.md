# Change: Implement Trait Matching via Embedding Similarity

## Why

Per `docs/architecture/algorithm.md` Section 3: "Calculate similarity between each candidate and the asked trait using embeddings (no text/boolean fallbacks)". Currently, `get_semantic_questions.sql` uses a binary join table (`place_traits`) instead of embedding similarity. This is a boolean fallback, not semantic matching.

## What Changes

- **Similarity calculation**: Compute embedding similarity between each candidate place and each trait using pgvector
- **Threshold-based matching**: Use `match_threshold` config to determine if a place "has" a trait
- **Remove join dependency**: Replace `LEFT JOIN place_traits` with similarity calculations
- **Performance**: Add appropriate indexes for pgvector similarity queries

## Impact

- Affected specs: algorithm
- Affected code: `supabase/db/game_logic/functions/questions/get_semantic_questions.sql`
- Enables true semantic understanding of place-trait relationships
