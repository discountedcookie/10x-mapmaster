# Architecture Rules

These rules apply to ALL agents (primary and subagents) working on this project.

## Database-First Architecture

**ALL business logic lives in PostgreSQL.** The frontend is presentation only.

| Layer        | Owns                                           | Does NOT Own                      |
| ------------ | ---------------------------------------------- | --------------------------------- |
| **Database** | Game mechanics, scoring, ranking, RLS, PostGIS | N/A - single source of truth      |
| **Frontend** | Presentation, user interaction, UI components  | Game logic, scoring, calculations |

### Implications

- Game rules, scoring algorithms, candidate ranking = PostgreSQL functions
- Frontend calls `supabase.rpc('function_name', params)` - never direct queries
- If you see game logic in frontend code, **flag it** - don't implement it there

## Source-Based Database Workflow

**Never edit migrations directly.** Always edit source files.

```
supabase/db/
├── schema/               # Tables, RLS policies, indexes
├── game_logic/functions/ # Internal game mechanics
└── public/functions/     # Player-facing RPC entrypoints
```

### Workflow

1. Edit source files in `supabase/db/`
2. Run `bun run db:rebuild` to generate migration + reset DB
3. Test with `supabase test db`
4. Commit BOTH source files AND generated migration

## Frontend Constraints

- **Stores** (`src/stores/`): Reactive state only, no business logic
- **Composables** (`src/composables/`): UI helpers, not game calculations
- **Components**: Call RPC functions, display results, handle errors

### Forbidden in Frontend

- Candidate ranking algorithms
- Confidence calculations
- Question effectiveness scoring
- Direct database queries (SELECT/INSERT/UPDATE)

## Security

- RLS policies on every table
- SECURITY DEFINER functions must validate `auth.uid()`
- Never expose sensitive data in frontend state

## Behavior

For honesty, session handling, and task discipline, follow `.opencode/rules/behavior.md`.
