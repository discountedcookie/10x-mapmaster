# Tasks: Add Base Config Tables

- [x] Create public.config table (key text PK, value jsonb)
- [x] Create game_logic.config table (key text PK, value jsonb) for private settings
- [x] Add constraints (key NOT NULL, value NOT NULL), comments
- [x] RLS: public.config readable by all; game_logic.config blocked except via service_role
- [x] Validate `openspec validate 03-base-config-tables --strict`
