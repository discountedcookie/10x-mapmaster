# Generate Database Migration

Generate safe, non-destructive SQL migrations for schema changes.

## Safety Rules

### ✅ SAFE Operations
- `CREATE TABLE` (with RLS)
- `ALTER TABLE ADD COLUMN` (with defaults)
- `CREATE INDEX`
- `CREATE FUNCTION`
- `CREATE POLICY`
- `INSERT INTO` (seed data)

### ❌ DANGEROUS (Production)
- `DROP TABLE` / `DROP COLUMN`
- `DELETE FROM` (without careful WHERE)
- `TRUNCATE`
- Disabling RLS

## Workflow

**1. Delegate to Gemini**

```javascript
mcp_zen_clink({
  cli_name: "gemini",
  prompt: `Generate safe PostgreSQL migration for 10x-mapmaster.

Requirements: [Describe schema changes]

Constraints:
- Non-destructive (production DB is LIVE)
- All tables must have RLS enabled
- Follow session-first architecture
- Use vector(384) for embeddings
- Include indexes and RLS policies

Current schema: See supabase/migrations/000001_initial_schema.sql`,
  absolute_file_paths: [
    "/Users/ciaastek/Projects/Sirocco/10x-mapmaster/supabase/migrations/000001_initial_schema.sql"
  ]
})
```

**2. Validate with Supabase MCP**

```javascript
mcp_supabase_apply_migration({
  name: "000004_your_migration_name",
  query: `-- Generated SQL`
})
```

**3. Test Locally**

```bash
npx supabase db reset   # Applies all migrations
npm test:db             # Verify tests pass
```

## Migration Template

```sql
-- Migration: [Description]
-- Safety: SAFE (non-destructive)

-- CREATE TABLE
CREATE TABLE IF NOT EXISTS new_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ENABLE RLS (REQUIRED)
ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;

-- INDEXES
CREATE INDEX idx_new_table_user_id ON new_table(user_id);

-- RLS POLICIES
CREATE POLICY "Users access own records"
ON new_table FOR ALL
USING (auth.uid() = user_id);
```

## RLS Policy Patterns

```sql
-- User isolation (most common)
CREATE POLICY "user_isolation"
ON table_name FOR ALL
USING (auth.uid() = user_id);

-- Public read, authenticated write
CREATE POLICY "public_read"
ON table_name FOR SELECT
USING (true);

CREATE POLICY "authenticated_write"
ON table_name FOR INSERT
WITH CHECK (auth.role() = 'authenticated');
```

## Validation Checklist

- [ ] Non-destructive
- [ ] RLS enabled on new tables
- [ ] RLS policies enforce isolation
- [ ] Indexes for performance
- [ ] Tested locally
- [ ] Database tests pass

## Security Review

Run after creation:
```
/analyze_security_impact
```
