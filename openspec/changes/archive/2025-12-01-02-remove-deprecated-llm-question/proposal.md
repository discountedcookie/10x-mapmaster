# Change: Remove Deprecated get_llm_question Function

## Why

The `get_llm_question()` function (345 lines) violates the documented architecture by allowing LLM to SELECT which question to ask. Per `docs/architecture/architecture.md`: "LLM does NOT: Select which trait to ask about (database logic)". The function is dead code - never called anywhere in the codebase.

## What Changes

- **Remove function**: Delete `supabase/db/game_logic/functions/questions/get_llm_question.sql` entirely
- **Remove seed prompt**: Delete the overly complex LLM prompt template from seed data that was designed for question selection
- **Clean up**: Remove any references to this function

## Impact

- Affected specs: database
- Affected code: `supabase/db/game_logic/functions/questions/get_llm_question.sql`, `supabase/seeds/00_static_data.sql`
- Reduces codebase complexity and eliminates architectural confusion
