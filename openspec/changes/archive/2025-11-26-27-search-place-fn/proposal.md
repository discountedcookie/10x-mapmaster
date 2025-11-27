# Change: Add search-place Edge Function

## Why

Provide a search endpoint for frontend autocomplete using Nominatim while normalizing responses.

## What Changes

- Implement search-place edge function to query Nominatim and return normalized suggestions
- Include basic filtering/sanitization

## Impact

- Affected specs: edge-functions
- Affected code: supabase/functions/search-place/index.ts and shared utils
