# Tasks: Database Foundation

## Phase 1 – Schema Scaffolding

- [x] 1.1 Configure required extensions (openspec/specs/database/spec.md#database-first-architecture) — ensure pgvector, PostGIS, pgcrypto, pg_cron enabled and documented
- [x] 1.2 Define geographic_regions table + indexes (openspec/specs/database/spec.md#core-data-tables)
- [x] 1.3 Define embeddings, places, traits, place_traits tables with constraints (openspec/specs/database/spec.md#core-data-tables)
- [x] 1.4 Define game_sessions and game_answers tables (openspec/specs/database/spec.md#core-data-tables)
- [x] 1.5 Add question_stats, config tables, rate_limit_log, error_response type (openspec/specs/database/spec.md#configuration-tables)

## Phase 2 – Security & Namespace

- [x] 2.1 Split schemas (public vs game_logic) and move private tables (openspec/specs/database/spec.md#schema-organization)
- [x] 2.2 Implement RLS for sessions/answers/config/access control (openspec/specs/database/spec.md#row-level-security)
- [x] 2.3 Create SECURITY DEFINER helpers that validate auth.uid() (openspec/specs/database/spec.md#security-definer-functions)

## Phase 3 – Observability & Config

- [x] 3.1 Create user_stats and global_stats views with RLS (openspec/specs/database/spec.md#stats-views)
- [x] 3.2 Implement rate limiting tables + cleanup job scaffolding (openspec/specs/database/spec.md#rate-limiting)
- [x] 3.3 Document schema layout and config usage in `supabase/db/schema/README.md`

## Phase 4 – Validation & Tooling

- [x] 4.1 Add pgTAP tests for schema + RLS (supabase/tests/test_game_basics.sql, test_settings_control_behavior.sql)
- [x] 4.2 Ensure `bun run db:rebuild` and `supabase test db` succeed on clean checkout (spec/operations.md#database-deployment)
