# Change: Add CI Pipeline

## Why

Ensure automated quality gates for linting, typing, unit tests, database tests, and E2E with mocks.

## What Changes

- Add CI workflows for lint/type/unit tests
- Add pgTAP database tests and Playwright E2E with mocked embeddings
- Upload coverage where appropriate

## Impact

- Affected specs: operations
- Affected code: .github/workflows/\*, scripts to run tests
