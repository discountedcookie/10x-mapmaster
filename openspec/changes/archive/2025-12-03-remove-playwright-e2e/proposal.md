# Change: Remove Playwright E2E Tests

## Why

E2E tests require complex mocking of Supabase and external services, creating maintenance burden. With comprehensive pgTAP coverage of all business logic in PostgreSQL, the E2E layer adds complexity without proportional value. Removing it simplifies CI and reduces false-positive failures from mock drift.

## What Changes

- Delete `e2e/` directory (fixtures, tsconfig)
- Delete `playwright.config.ts`
- Remove `@playwright/test` dependency from package.json
- Remove E2E scripts from package.json (`test:e2e`, update `test` and `test:all`)
- Remove E2E job from `.github/workflows/ci.yml`
- Update deploy job dependencies to not require E2E
- Update `tsconfig.node.json` to remove playwright reference

## Impact

- Affected specs: operations (CI pipeline definition)
- Affected code: `e2e/`, `playwright.config.ts`, `package.json`, `.github/workflows/ci.yml`, `tsconfig.node.json`
- Test strategy becomes: unit tests (vitest) + database tests (pgTAP)
