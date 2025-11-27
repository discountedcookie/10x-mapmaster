# Change: Add Learning Trigger

## Why

Automatically invoke trait regeneration when a session transitions out of pending review.

## What Changes

- Create trigger function and trigger on game_sessions pending_review TRUE→FALSE
- Ensure it calls regenerate_place_traits with linked place

## Impact

- Affected specs: database
- Affected code: supabase/db/functions/triggers/\*, supabase/db/schema/triggers.sql
