# Change: Add call-llm Edge Function

## Why

Expose a provider-agnostic LLM call for question generation and trait extraction.

## What Changes

- Implement call-llm edge function with configurable provider, model, temperature, prompt
- Standardize error mapping and logging

## Impact

- Affected specs: edge-functions
- Affected code: supabase/functions/call-llm/index.ts and shared utils
