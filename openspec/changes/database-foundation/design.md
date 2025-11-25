# Design: Database Foundation

## Execution Plan

1. **Schema scaffolding (1.x)** – Ensure extensions, schemas, and core tables exist and follow spec naming.
2. **Security layering (2.x)** – Apply RLS, SECURITY DEFINER helpers, and schema separation.
3. **Observability (3.x)** – Add stats views, error types, and rate limiting tables.
4. **Validation (4.x)** – pgTAP coverage and documentation for source-based workflow.

## Dependencies

- Phase 1 must finish before security policies can be applied.
- Stats views depend on finalized table shapes.
- Tests rely on both schema and policies being present.

## Agents

- **Primary:** @supabase-expert
- **Support:** build agent for docs/tooling updates

## Risks & Mitigations

| Risk                                              | Mitigation                                                                   |
| ------------------------------------------------- | ---------------------------------------------------------------------------- |
| Existing 1024d embeddings conflict with 384d spec | Document decision, keep consistent dimension for now                         |
| Missing pgTAP coverage                            | Create focused tests in `supabase/tests/` as part of tasks                   |
| Config drift                                      | Move all runtime config into tables with comments, add docs in schema README |
