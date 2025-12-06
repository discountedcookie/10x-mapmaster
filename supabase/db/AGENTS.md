# Database Rules

This is where **ALL business logic** lives.

## Workflow

1. Edit source files in `supabase/db/schema/` or `supabase/db/*/functions/`
2. Run `bun run db:rebuild` to generate migration + reset DB
3. Test with `supabase test db`
4. Commit BOTH source files AND generated migration

**Never edit migrations directly.**

## Schema Organization

```
schema/           # Tables, RLS policies, indexes, types
game_logic/       # Internal functions (scoring, questions)
public/           # Player-facing RPC entrypoints
```

## SQL Style

- UPPERCASE keywords: `SELECT`, `FROM`, `WHERE`, `INSERT`
- lowercase identifiers: `places`, `game_sessions`, `user_id`
- Explicit column lists (no `SELECT *`)
- Comments for non-obvious logic

## Security Model

| Schema       | Access           | Use For             |
| ------------ | ---------------- | ------------------- |
| `public`     | RLS-protected    | User-facing data    |
| `game_logic` | SECURITY DEFINER | Internal algorithms |

- RLS policies MUST use `auth.uid()` for user data
- SECURITY DEFINER only for privileged operations
- Never expose `game_logic` functions directly

## Testing

Every function needs pgTAP tests in `supabase/tests/`.
Run: `supabase test db`
