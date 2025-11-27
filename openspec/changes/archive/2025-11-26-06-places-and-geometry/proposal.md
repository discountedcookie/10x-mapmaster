# Change: Add Places and Geometry

## Why

Store places with geometry, embeddings, and review status to support gameplay and map visualization.

## What Changes

- Create places table with geom, osm_id, embedding_id, pending_review, timestamps
- Add constraints and indexes (GIST on geom, unique osm_id, name index)
- Define RLS posture for read-open places

## Impact

- Affected specs: database
- Affected code: supabase/db/public/tables/places.sql
