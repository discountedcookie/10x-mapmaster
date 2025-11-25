# Design: Operations Platform

## Execution Plan

1. **Environment + tooling** – Scripts, env templates, docs.
2. **CI/CD** – Lint/type/test/build pipelines, deployment automation.
3. **Security** – CodeQL, Semgrep, Dependabot, rate limiting validation.
4. **Monitoring** – Logging strategy, Sentry wiring, cleanup jobs.
5. **Governance** – Branch rules, commit conventions, PR templates.

## Dependencies

- Relies on other capabilities for runnable code, but many tasks can run in parallel (docs, scripts, CI).

## Agents

- **Primary:** build agent
- **Support:** @supabase-expert for DB-specific tasks, @frontend-expert for UI tests

## Risks & Mitigations

| Risk           | Mitigation                                                  |
| -------------- | ----------------------------------------------------------- |
| CI flakiness   | Use deterministic mocks, document rerun strategy            |
| Security noise | Tune Semgrep/CodeQL configs, triage baseline                |
| Docs drift     | Source of truth is spec + OpenSpec tasks; keep README short |
