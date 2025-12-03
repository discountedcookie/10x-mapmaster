# Change: Fix Existing Failing Unit Tests

## Why

The current unit test suite has numerous failures (e.g., incorrect imports, outdated expectations, missing mocks). These failures block CI and obscure real regressions.

## What Changes

- Diagnose and fix failing tests without introducing new behavior changes, focusing on imports, mocks, and expectations that no longer match the implementation.
- Bring the unit test suite back to green.

## Impact

- Affected specs: `frontend`, `game-core` (testing quality and verification).
- Affected code: existing tests in `src/__tests__` (e.g., game store, places store, i18n, App, GamePlaceSearch, useStatistics).
- Restores trust in the unit test suite as a safety net for changes.
