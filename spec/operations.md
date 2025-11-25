# Operations

## Environments

### Development

- Local Supabase instance
- Ollama for local embeddings (384d, gte-small compatible)
- Debug logging enabled
- Hot reload for rapid iteration
- Migration command: `bun run db:rebuild` (clean reset)

### Production

- Production Supabase cluster
- Supabase gte-small for embeddings (384d)
- Third-party LLM provider (TBD)
- GitHub Pages for static frontend hosting
- Migration command: `bun run db:build-migration --prod "description"` (incremental)
- Single remote environment: the same Supabase project is used for CI tests and production traffic (no separate staging environment)

## Database Deployment

### Migration Strategy

**Development:**

- Single clean migration with database reset
- Fast iteration, no migration history
- Rebuilds entire schema from source files

**Production:**

- Incremental migrations with timestamps
- Preserves migration history
- Rollback capability

### Seed Data

- Static data: Places, traits, geographic regions
- Configuration: `public.config` and `game_logic.config` tables
- Pre-generated embeddings included
- Natural Earth data for geographic regions

## Admin Workflows

All admin workflows are performed through Supabase Studio or direct SQL access only; there is no dedicated admin UI in the application.

### Review Pending Sessions

**Purpose:** Prevent spam while allowing legitimate anonymous gameplay

**Process:**

1. Query `game_sessions` where `pending_review = true`
2. Review session details: description, questions asked, answers given
3. Decision:
   - **Approve**: Set `pending_review = false` → Triggers learning
   - **Reject (spam)**: Delete the session record

**Database trigger on approval:**

- Applies learning (trait extraction, embedding regeneration)
- Approves associated places

**Automatic approval:**

- Registered users: Sessions created with `pending_review = false`
- Anonymous user upgrades: All their pending sessions auto-approved

### Review Pending Places

**Purpose:** Control which places appear in candidate matching

**Process:**

- Places automatically approved when their session is approved
- Direct place approval not typically needed
- New places excluded from matching until approved

### Configuration Management

**Access:** Direct database access via Supabase Studio or any PostgreSQL client

**Effect:** Changes take effect on next RPC function call (functions read config when invoked)

**No restart required** - Configuration is database-driven, no code deployment needed

### Production Data Management

**Geographic Regions:**

- Added via database migrations
- Source: Natural Earth data
- Updates through migration files

**Places:**

- Primary source: User submissions via gameplay
- Seed data: Minimal initial set (20 iconic places)
- Seeding uses production enrichment logic (no code duplication)
- Seed places not connected to game sessions

**Adding Seed Places:**

1. Add OSM ID to seed data file
2. Seed script calls production enrichment functions
3. Place goes through normal enrichment pipeline
4. Stored with all traits, embeddings, geometry

## Frontend Deployment

### Build Process

- Type check: `bun run type-check`
- Build: `bun run build`
- Output: Static files in `dist/`

### Deployment Target

- **GitHub Pages** - Static hosting
- Automated via GitHub Actions
- Environment variables set in build process

### Environment Variables

- `VITE_SUPABASE_URL` - Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Public anonymous key
- `VITE_SENTRY_DSN` - Sentry DSN for frontend error tracking

## CI/CD Pipeline

### Automated Testing

- **Lint and Type Check** – Code quality validation (oxlint + ESLint + `vue-tsc`), run via Bun in CI (for example, `bun run lint`, `bun run type-check`).
- **Database Tests** – pgTAP via `supabase test db` for core game logic and security invariants.
- **Unit Tests** – Vitest with coverage reports to Codecov, run via `bun run test:unit:coverage`.
- **E2E Tests** – Playwright for end-to-end flows (Chromium + mobile viewport, using mocked embeddings), run via `bun run test:e2e`.
- All of the above run in CI on every push and pull request; deployment to `main` only happens after they pass.

### Deployment

- **GitHub Pages** - Automatic deployment on main branch
- Triggered after all tests pass
- Static build from `dist/` directory

## Development Tooling

### Code Quality

**Dual-layer linting:**

- Fast linter (oxlint) for immediate feedback during development
- Comprehensive linter (ESLint) for full rule coverage in CI
- Both run in parallel for speed

**ESLint focus areas:**

- Vue single-file component best practices
- TypeScript strict mode compliance
- Code consistency (unicorn plugin)
- Prettier conflict resolution

**File size limit:** Max 200 lines per file (encourages modular code)

### Formatting

**Prettier for all code:**

- Consistent style across TypeScript, Vue, JSON
- SQL formatting with PostgreSQL dialect (uppercase keywords, lowercase identifiers)
- Format-on-save recommended

### Supabase Types Generation

- TypeScript types for database tables, views, and functions are generated with the Supabase CLI:
  - `supabase gen types --lang=typescript --local > src/types/database.ts`
- A `supabase:types` script is defined in `package.json` to automate this:
  - For example: `"supabase:types": "supabase gen types --lang=typescript --local > src/types/database.ts"`
- Developers run this script after schema changes so the frontend always consumes up-to-date generated types.

### Git Workflow

**Branch strategy:**

- `main` - Production-ready, deploys automatically
- Feature branches for all changes
- No direct commits to main

**Pull requests:**

- Required for all changes to main
- Must pass CI (lint, type-check, tests)
- Template provided for consistent descriptions

**Commit conventions:**

- Scoped prefixes: `feat:`, `fix:`, `chore:`, `docs:`
- Dependency updates: `chore(deps):`, `chore(actions):`

### Local Development

**Prerequisites:**

- Bun (primary script runner for frontend and database tooling)
- Docker (for local Supabase)
- Ollama (for local LLM/embeddings)

**No pre-commit hooks** - Linting runs in CI. Developers can run `bun run lint` locally before pushing.

## Security and Monitoring

### Automated Security Scans

- **CodeQL** - GitHub's default code scanning
- **NPM Audit** - Dependency vulnerability checking
- **Semgrep** - Security pattern scanning (security-audit, secrets, typescript, vue)
- **Trufflehog** - Secret detection in commits
- **OSSF Scorecard** - Security best practices scoring (weekly on main)
- **Bundle Size** - Track bundle size changes on PRs

### Rate Limiting

**Purpose:** Prevent abuse while allowing normal gameplay patterns.

**Limits (per authenticated user):**

| Endpoint       | Limit | Window   | Rationale                              |
| -------------- | ----- | -------- | -------------------------------------- |
| `start_game`   | 10    | 1 minute | Allows quick retries, blocks auto-spam |
| `play_turn`    | 60    | 1 minute | 1/sec generous for humans, stops bots  |
| `submit_place` | 10    | 1 minute | Allows UI retries, blocks spam         |

These limits are invisible to normal users while blocking automated attacks (100s+ requests/sec).

**Implementation:**

- Database-enforced via `check_rate_limit(user_id, action)` function
- Tracks requests in `rate_limit_log` table (user_id, action, timestamp)
- Function checks count within window before allowing operation
- Returns error code `rate_limit_exceeded` (429) when exceeded
- Cleanup: pg_cron job deletes entries older than window

**Anonymous vs Registered:** Same limits apply (both have `auth.uid()` from Supabase auth).

**No IP-based limiting:** All users authenticated via Supabase (regular or anonymous auth), so user-based limits are sufficient.

### Logging and Monitoring

Simple logging strategy with light external error tracking where it adds value.

| Layer          | Approach                                                            |
| -------------- | ------------------------------------------------------------------- |
| Database       | PostgreSQL logs managed by Supabase (automatic)                     |
| Edge Functions | `console.log/error` - visible in Supabase dashboard                 |
| Frontend       | consola library for structured logging + Sentry for error reporting |

**What to log:**

- Edge functions: LLM/embedding API calls (duration, success/failure)
- Frontend: Errors and key user actions (game start, completion)

**What NOT to log:**

- User descriptions or personal data
- Sensitive configuration values

**Monitoring:**

- Supabase dashboard for database and edge-function logs
- Sentry dashboard for frontend error visibility (DSN provided via environment variables)
- No other external monitoring or alerting services are used.

### Dependency Management

- **Dependabot** - Weekly automated updates (Mondays)
  - NPM dependencies: Groups minor/patch, separates major
  - GitHub Actions: Weekly updates
  - Auto-labeled and scoped commits

## Backup and Maintenance

### Backups

- Supabase default automated backups
- Point-in-time recovery available
- Configuration managed by Supabase

### Automated Maintenance

**Abandoned Session Cleanup:**

Daily cron job (Supabase pg_cron) removes abandoned game sessions:

```sql
-- Runs daily
DELETE FROM game_sessions
WHERE
  status = 'active'
  AND updated_at < NOW () - INTERVAL '24 hours';
```

Sessions are considered abandoned if no activity (answers) for 24 hours. Hard delete removes session and cascades to answers.

### Manual Tasks

- Review and approve pending sessions (database access)
- Delete spam sessions (database access)
- Review and merge Dependabot PRs
- Monitor security alerts from automated scans

## Testing Strategy

Focus on smart coverage of critical paths, not exhaustive edge cases.

### Testing Frameworks

| Layer    | Framework  | Environment                |
| -------- | ---------- | -------------------------- |
| Database | pgTAP      | Supabase test runner       |
| Unit     | Vitest     | jsdom (browser simulation) |
| E2E      | Playwright | Chromium + Mobile Chrome   |

**Coverage:** Track via Codecov, no hard threshold enforced (quality over quantity).

### Database (pgTAP)

**Functional tests:**

- Core game logic: `start_game`, `play_turn`, `submit_place`
- Learning trigger: trait extraction, embedding regeneration
- Candidate scoring: similarity calculations, confidence metrics

**Security tests:**

- RLS policies: user isolation, anonymous access
- Input validation: length limits, injection patterns
- Function permissions: SECURITY DEFINER validation

### Edge Functions

- Contract tests: correct input/output shapes
- Provider integration: LLM and embedding calls work
- Error handling: graceful failures

### Frontend Unit (Vitest)

- Composables with business logic (game state management)
- Store actions and getters
- Utility functions

### E2E (Playwright)

Critical happy paths only:

- Start game → answer questions → win
- Start game → give up → submit place
- Anonymous → register → history preserved

### What NOT to Test

- Button click handlers (UI framework responsibility)
- Input trimming, basic validation
- Extreme edge cases unlikely in practice
- 100% coverage for its own sake
