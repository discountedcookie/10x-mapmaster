# Change: Add submit_place RPC

## Why

Allow players to submit the correct place after giving up, trigger enrichment, and apply review rules.

## What Changes

- Implement submit_place RPC with needs_submission guard and ownership checks
- Call enrichment (edge function), create/update place, link session, set pending_review based on user type
- Trigger learning for registered users on auto-approval

## Impact

- Affected specs: game-core
- Affected code: supabase/db/public/functions/submit_place.sql and dependencies
