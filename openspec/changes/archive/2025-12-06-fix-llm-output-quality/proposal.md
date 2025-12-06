# Change: Fix LLM output quality (sanitization + fact filtering)

## Why

Two issues with LLM-generated content:

1. **HTML artifacts**: Questions sometimes contain raw markup like `<s> [OUT]` leaked from LLM training data
2. **False facts**: The system learns obviously false claims (e.g., "nuclear reactor" at Angkor Wat) without validation

Both issues stem from insufficient output processing in the LLM pipeline.

## What Changes

- Add output sanitization to strip HTML tags and common LLM artifacts
- Update trait extraction prompt to instruct LLM to filter unreliable/unverifiable claims
- Add post-processing to validate trait quality before storage

## Impact

- Affected specs: edge-functions
- Affected code: `supabase/functions/call-llm/`, `supabase/db/game_logic/data/config.sql`
- **BREAKING**: None - improvements are transparent to callers
