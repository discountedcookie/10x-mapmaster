# Tasks: Add Config and Extensions

- [x] Create schemas: extensions, public, game_logic; grant usage as required
- [x] Install extensions: pgvector (set default dimension 384 where applicable), PostGIS, pg_cron
- [x] Define enums/types: status enums, answer_value enum, other shared types
- [x] Set search_path defaults for functions (public, game_logic, extensions)
- [x] Document extension schemas in schema README; validate `openspec validate 02-config-and-extensions --strict`

## Implementation Notes

### Schemas

- `extensions`: Supabase default schema (pre-created by platform)
- `public`: PostgreSQL default schema
- `game_logic`: Created at `supabase/db/schema/01_extensions.sql:221` with GRANT USAGE

### Extensions Installed (`01_extensions.sql`)

- pg_cron (line 48-50) - pg_catalog schema
- pg_net (line 75-77) - extensions schema
- http (line 81-83) - extensions schema
- pg_graphql (line 87-89) - graphql schema
- pg_stat_statements (line 93-95) - extensions schema
- pgcrypto (line 99-101) - extensions schema
- PostGIS (line 105-107) - extensions schema
- supabase_vault (line 111-113) - vault schema
- uuid-ossp (line 117-119) - extensions schema
- pgvector (line 123-125) - extensions schema, 384d configured in all vector columns

### Enums/Types Defined (`01_extensions.sql`)

- `game_session_status` (lines 141-146): active, won, ended, needs_submission
- `question_type` (lines 161-164): geographic, semantic
- `geographic_level` (lines 177-181): continent, region, country
- `error_response` (lines 192-196): composite type for RPC errors
- `answer_value` (line 209): yes, no, not_sure

### search_path

- All functions set `search_path = public, game_logic, extensions` explicitly
- 56+ functions verified with explicit search_path
