# Workflow: Essential Safety Rules

## Critical Safety Rules (Never Break)

### Production Database Operations
**NEVER run these commands:**
- ❌ `supabase db reset --remote`
- ❌ `supabase db push` without user approval
- ❌ Any command with `--remote` flag

### Seed Scripts (Require Environment Variables)
**NEVER run these commands:**
- ❌ `npm run seed:places`
- ❌ `npm run seed:questions`
- ❌ Any script that needs API keys or env variables

**Why:** These require production environment variables that only the user has access to.

### Destructive Database Operations
**NEVER run these commands:**
- ❌ `DROP TABLE` / `DROP COLUMN`
- ❌ `TRUNCATE TABLE`
- ❌ `DELETE` without `WHERE` clause
- ❌ `ALTER TABLE` that loses data

## Always Safe Commands

### Local Development (Always OK)
- ✅ `npx supabase db reset` - Local DB reset (SAFE)
- ✅ `npm run dev` - Development server
- ✅ `npm test` - Unit tests
- ✅ `npm run test:db` - Database tests
- ✅ `npm run test:e2e` - E2E tests (local only)
- ✅ `npm run lint` - Linter
- ✅ `npm run type-check` - TypeScript check
- ✅ `npm run build` - Production build
- ✅ `npm run supabase:types` - Type generation

### Database Queries (Always OK)
- ✅ `mcp_supabase_execute_sql` for queries
- ✅ `mcp_supabase_apply_migration` for schema changes
- ✅ Local database operations

## Git Safety Rules

### Always Safe
- ✅ Feature branches: `git checkout -b feature/<name>`
- ✅ Commits with Conventional Commits format
- ✅ Push to feature branches

### Ask User First
- ❌ Push to main/master
- ❌ Force push: `git push --force`
- ❌ Rebase published branches

## Production Safeguards

### Always Enabled
- ✅ RLS policies on all tables
- ✅ Non-destructive migrations only
- ✅ Feature branches for all work

### Never on Production
- ❌ Direct database manipulation
- ❌ Manual data changes
- ❌ Schema changes without migration
- ❌ Disabling RLS

## When in Doubt

**Ask user for:**
- Production database operations
- Deployment to production
- Running scripts with env variables
- Any `--remote` or `--force` flags

## Simple Rule

**If it affects production or requires credentials, ask the user first. Everything else is safe to do locally.**

## Cline-Specific Guidelines

### Tool Usage
- ✅ Use `execute_command` for local development commands
- ✅ Use MCP tools for database queries and migrations
- ❌ Never use tools that require production credentials

### Memory Updates
- ✅ Update memory MCP with observations and learnings
- ✅ Create new_task for session handoffs
- ✅ Update docs only when architecture/workflows change

### Safety First
Always check this document before running any command that could affect production data or require credentials.
