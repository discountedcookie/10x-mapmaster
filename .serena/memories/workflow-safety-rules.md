# Workflow: Critical Safety Rules

## NEVER Run These Commands

**Seed Scripts (require env variables, user-only):**
- ❌ `npm run seed:places`
- ❌ `npm run seed:questions`
- ❌ Any script that needs API keys or env variables

**Production Database:**
- ❌ `supabase db reset --remote`
- ❌ `supabase db push` without user approval
- ❌ Any command with `--remote` flag

**Destructive Operations:**
- ❌ DROP table/column
- ❌ TRUNCATE table
- ❌ DELETE without WHERE clause
- ❌ ALTER TABLE that loses data

## ALWAYS Run These Commands

**Safe local commands:**
- ✅ `npm supabase db dump` - Remote database dump
- ✅ `npm supabase db diff` - Local database diff
- ✅ `npx supabase db reset` - Local database reset
- ✅ `npm test` - Unit tests
- ✅ `npm run test:unit` - Unit tests
- ✅ `npm run test:db` - Database tests
- ✅ `npm run lint` - Linter
- ✅ `npm run type-check` - TypeScript check
- ✅ `npm run dev` - Development server
- ✅ `npm run build` - Production build

## Database Operation Rules

**Supabase MCP (preferred):**
- ✅ Use `mcp_supabase_execute_sql` for queries
- ✅ Use `mcp_supabase_apply_migration` for schema changes
- ❌ Never use terminal `supabase db push` without asking user

**Migration Pattern:**
1. Create migration file in `supabase/migrations/`
2. Test with `npx supabase db reset` (applies all migrations)
3. Use Supabase MCP to apply migration
4. Regenerate types: `npm run supabase:types`

## Seeding Workflow

**Correct pattern:**
1. Agent resets local DB: `npx supabase db reset`
2. Agent asks user to run: `npm run seed:places && npm run seed:questions`
3. Agent verifies with Supabase MCP queries

**Why user must run seeds:**
- Require production environment variables
- Call production edge function for embeddings
- Agent does NOT have access to these credentials

## Production Safeguards

**ALWAYS enabled:**
- ✅ RLS policies on all tables
- ✅ Non-destructive migrations only
- ✅ Feature branches for all work
- ✅ Security review for schema/auth changes

**NEVER on production:**
- ❌ Direct database manipulation
- ❌ Manual data changes
- ❌ Schema changes without migration
- ❌ Disabling RLS

## Git Safety Rules

**Safe operations:**
- ✅ Feature branches: `git checkout -b feature/<name>`
- ✅ Commits with Conventional Commits format
- ✅ Push to feature branches

**Ask user first:**
- ❌ Force push: `git push --force`
- ❌ Push to main/master
- ❌ Rebase published branches
- ❌ Amend pushed commits

## Security Review Triggers

**MUST run `/analyze_security_impact` before committing:**
- Changes to RLS policies
- Changes to authentication logic
- New database functions with security implications
- Changes to user data access patterns

## Quality Gates

**Before commit (BLOCKING):**
- Lint: `npm run lint`
- Type check: `npm run type-check`
- Unit tests: `npm test`

**Before PR merge (BLOCKING):**
- All commit checks pass
- Database tests: `npm run test:db`
- E2E tests: `npm run test:e2e` (local only)
- Code review: `/review_code_changes`
- Security review (if schema/auth changed): `/analyze_security_impact`

## When in Doubt

**Ask user for:**
- Production database operations
- Deployment to production
- Breaking changes to public API
- Running scripts with env variables
- Any `--remote` or `--force` flags