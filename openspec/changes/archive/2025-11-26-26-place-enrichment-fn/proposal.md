# Change: Add place-enrichment Edge Function

## Why

Fetch and normalize Nominatim data and run trait extraction for submitted places.

## What Changes

- Implement place-enrichment edge function to fetch Nominatim details and extract traits
- Return structured payload for database consumption

## Impact

- Affected specs: edge-functions
- Affected code: supabase/functions/place-enrichment/index.ts and shared utils
