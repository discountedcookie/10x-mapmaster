# Tasks: Add Auth Basics

- [x] Define auth personas: anonymous (auth.uid() nullable), registered (auth.uid() set), service_role
- [x] Document SECURITY DEFINER guardrails: auth.uid() IS NOT NULL checks when user context required; explicit search_path (public, game_logic, extensions)
- [x] Define RLS posture: user-owned tables (sessions/answers) enforce auth.uid() = user_id or anonymous ownership; public tables read-open; private tables blocked
- [x] Add policy templates and comments in schema README for consistent use
- [x] Tests/docs: note required policies and checks; validate `openspec validate 01-auth-basics --strict`

## Implementation Notes

### Changes Made

1. **submit_place.sql**: Added `auth.uid() IS NOT NULL` check at function start (SECURITY DEFINER guardrail)
2. **start_game.sql**: Added `extensions` to search_path
3. **play_turn.sql**: Added `extensions` to search_path
4. **schema/README.md**: Added comprehensive Auth Model documentation including:
   - Auth Personas table (Anonymous, Authenticated, Service Role)
   - SECURITY DEFINER Guardrails with template
   - RLS Posture with policy templates

### Validation

- `openspec validate 01-auth-basics --strict` passes
- `test_rls_policies.sql` (20 tests) passes - validates auth personas and RLS patterns
