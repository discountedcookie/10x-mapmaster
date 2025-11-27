# Tasks: Add CI Pipeline

- [ ] Workflow job for lint/type/unit (bun run lint, type-check, unit tests) with caching
- [ ] Workflow job for pgTAP database tests (supabase test db) with required services
- [ ] Workflow job for Playwright E2E using mocked embeddings; install browsers; run headless
- [ ] Coverage upload (unit/E2E as applicable) to reporting service
- [ ] Ensure jobs run on PR and main; doc badges/links if used
- [ ] Validate `openspec validate 34-ci-pipeline --strict`
