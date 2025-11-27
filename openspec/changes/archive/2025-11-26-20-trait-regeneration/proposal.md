# Change: Add Trait Regeneration

## Why

Rebuild a place’s traits and embedding from combined Nominatim data and approved session descriptions.

## What Changes

- Implement regenerate_place_traits function
- Combine place enrichment data and approved session descriptions to produce traits and new embedding

## Impact

- Affected specs: database
- Affected code: supabase/db/game_logic/functions/places/regenerate_place_traits.sql
