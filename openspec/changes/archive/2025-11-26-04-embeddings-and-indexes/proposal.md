# Change: Add Embeddings and Indexes

## Why

Store text embeddings with appropriate constraints and indexes to support semantic search.

## What Changes

- Create embeddings table with source_text and 384d vector
- Add constraints and HNSW index on embedding column
- Document usage and ownership

## Impact

- Affected specs: database
- Affected code: supabase/db/public/tables/embeddings.sql
