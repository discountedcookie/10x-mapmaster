# Generate Database Migration (Local)

Guidance for writing and testing safe, non-destructive SQL migrations.

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

**1. Write Migration SQL**

Use the template below to write your migration file. Place it in `supabase/migrations/`.

**2. Test Locally**

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

## Validation Checklist

- [ ] Non-destructive
- [ ] RLS enabled on new tables
- [ ] RLS policies enforce isolation
- [ ] Indexes for performance
- [ ] Tested locally
- [ ] Database tests pass
