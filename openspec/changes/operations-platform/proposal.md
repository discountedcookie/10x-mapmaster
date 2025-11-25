# Change: Operations Platform

## Why

To keep the project healthy we need reproducible environments, CI/CD, security scans, and documentation. The spec describes comprehensive operations requirements that must be landed once core features are ready.

## Scope

- Development/production environment parity
- Database migration workflow + seeds
- CI/CD (lint, type-check, tests, deployments)
- Security scanning + rate limiting verification
- Logging/monitoring + maintenance jobs
- Git workflow + branch protections

## Impact

- Improves contributor confidence
- Protects production with automated checks
- Ensures security posture matches README claims

## Success Criteria

- GitHub Actions pipelines green (ci.yml, security.yml)
- Scripts (`bun run db:rebuild`, `supabase test db`, `bun run test:e2e`) documented and passing
- SECURITY.md, README.md aligned with current architecture
- Branch protections and Dependabot configured
