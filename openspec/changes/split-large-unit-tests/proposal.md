# Change: Split Oversized Unit Test Suites

## Why

Several unit test files exceed the projects 200-line guideline (e.g., `game.spec.ts`, `places.spec.ts`, `useStatistics.spec.ts`), making them harder to navigate and maintain. ESLint raises warnings, and test responsibilities are blurred within large files.

## What Changes

- Split oversized test files into smaller, focused suites organized by responsibility.
- Keep test behavior the same while improving structure and readability.
- Remove ESLint max-lines warnings related to these files.

## Impact

- Affected specs: `frontend` (testing conventions).
- Affected code: `src/__tests__/stores/game.spec.ts`, `src/__tests__/stores/places.spec.ts`, `src/__tests__/composables/useStatistics.spec.ts`.
- Simplifies future changes and reduces friction when updating tests.
