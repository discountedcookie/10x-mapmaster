# Tasks: Operations Platform

## Phase 1 – Environment & Tooling

- [ ] 1.1 Update `.env.example` + docs for Bun/Supabase/Ollama (spec/operations.md#development-tooling)
- [ ] 1.2 Document local workflow in README (spec/operations.md#getting-started)
- [ ] 1.3 Ensure `bun run db:rebuild` and seeds cover all tables (spec/operations.md#database-deployment)

## Phase 2 – CI/CD

- [ ] 2.1 ci.yml: lint, type-check, unit tests (spec/operations.md#ci/cd-pipeline)
- [ ] 2.2 security.yml: CodeQL, Semgrep, Trufflehog, Scorecard (spec/operations.md#security-and-monitoring)
- [ ] 2.3 Deploy frontend to GitHub Pages on main (spec/operations.md#frontend-deployment)

## Phase 3 – Testing Infrastructure

- [ ] 3.1 `supabase test db` integration in CI (spec/operations.md#testing-strategy)
- [ ] 3.2 Vitest + coverage upload (spec/operations.md#testing-strategy)
- [ ] 3.3 Playwright pipeline with mocked embeddings (spec/operations.md#testing-strategy)

## Phase 4 – Security & Monitoring

- [ ] 4.1 Configure Sentry (frontend) + logging strategy (spec/operations.md#logging-and-monitoring)
- [ ] 4.2 Verify rate limiting via pgTAP + E2E (spec/operations.md#rate-limiting)
- [ ] 4.3 Document security policy in `.github/SECURITY.md` (spec/operations.md#security-and-monitoring)

## Phase 5 – Maintenance & Governance

- [ ] 5.1 Configure pg_cron jobs for cleanup (spec/operations.md#automated-maintenance)
- [ ] 5.2 Dependabot groups + schedule (spec/operations.md#dependency-management)
- [ ] 5.3 Branch protections + commit template (spec/operations.md#git-workflow)
