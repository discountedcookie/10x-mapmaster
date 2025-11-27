# Change: Add generate-embedding Edge Function

## Why

Provide a provider-agnostic edge function to return 384d embeddings for text.

## What Changes

- Implement generate-embedding edge function with config-driven provider selection
- Add error mapping and tests/mocks

## Impact

- Affected specs: edge-functions
- Affected code: supabase/functions/generate-embedding/index.ts and shared utils
