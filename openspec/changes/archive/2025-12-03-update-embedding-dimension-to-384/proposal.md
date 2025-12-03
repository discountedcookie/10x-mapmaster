# Change: Make 384-Dimensional Embeddings Canonical

## Why

The current documentation still refers to 1024-dimensional embeddings, but the actual implementation uses 384-dimensional embeddings (e.g., all-MiniLM-L6-v2). This mismatch can confuse contributors and lead to incorrect index or storage assumptions.

## What Changes

- Update all specs and docs to consistently describe embeddings as 384-dimensional.
- Confirm that database schema and edge functions already use 384 dimensions, and document this explicitly.
- Remove or correct any references to 1024d vectors.

## Impact

- Affected specs: `database`, `algorithm`, `edge-functions`.
- Affected docs: `supabase/db/schema/QUICK_REFERENCE.md`, any architecture docs mentioning dimension size.
- No runtime behavior change; this is a consistency and clarity fix aligning docs/specs with reality.
