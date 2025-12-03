# Tasks: remove-playwright-e2e

## 1. Remove E2E Test Files

- [x] 1.1 Delete `e2e/fixtures/index.ts`
- [x] 1.2 Delete `e2e/fixtures/mock-embeddings.ts`
- [x] 1.3 Delete `e2e/fixtures/mock-supabase.ts`
- [x] 1.4 Delete `e2e/tsconfig.json`
- [x] 1.5 Delete `e2e/` directory
- [x] 1.6 Delete `playwright.config.ts`

## 2. Update Package Configuration

- [x] 2.1 Remove `@playwright/test` from devDependencies in `package.json`
- [x] 2.2 Remove `test:e2e` script from `package.json`
- [x] 2.3 Update `test` script to remove `test:e2e` (keep `test:unit test:db`)
- [x] 2.4 Update `test:all` script to remove `test:e2e`
- [x] 2.5 Remove `playwright.config.ts` from `tsconfig.node.json` include array

## 3. Update CI Workflow

- [x] 3.1 Remove entire `e2e` job from `.github/workflows/ci.yml` (lines 102-147)
- [x] 3.2 Update `deploy` job `needs` from `[test, e2e]` to `[test]`

## 4. Update Related OpenSpec Changes

- [x] 4.1 Update `34-ci-pipeline` spec delta to remove E2E scenario
- [x] 4.2 Update `34-ci-pipeline` tasks to remove E2E task

## 5. Validation

- [x] 5.1 Run `npm run test` to verify test scripts work without e2e
- [x] 5.2 Run `openspec validate remove-playwright-e2e --strict`
