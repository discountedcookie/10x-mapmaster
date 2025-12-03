# Change: Add Database Tests for submit_place

## Why

The `submit_place` RPC is a critical part of the game flow, handling place submission, enrichment, and review state after a game ends. Currently, there are no dedicated pgTAP tests for this function, which leaves behavior under-specified and fragile.

## What Changes

- Extend the `game-core` and `database` specs with detailed `submit_place` requirements and scenarios.
- Add a dedicated pgTAP test file that covers success and failure scenarios for `submit_place`.
- Ensure error and rate-limiting behaviors are exercised and documented.

## Impact

- Affected specs: `game-core`, `database`.
- Affected code: `supabase/db/public/functions/submit_place.sql` (behavior contract only), new tests in `supabase/tests/test_submit_place.sql`.
- Increases confidence in the correctness and stability of the submission workflow.
