# Design: Game Core

## Execution Plan

1. **Session orchestration** – Implement RPC functions and helper procedures for turn flow.
2. **Answer/guess pipeline** – Record answers, update candidates, decide next turn.
3. **Place submission** – Integrate with edge functions to enrich or link places.
4. **Learning + approval** – Trigger trait regeneration when sessions approved.
5. **Maintenance** – Cleanup abandoned sessions and pending items.

## Dependencies

- Requires database foundation + algorithm engine + edge functions.
- Frontend can parallelize once RPC contracts are stable.

## Agents

- **Primary:** @supabase-expert
- **Support:** build agent for cron + docs

## Risks & Mitigations

| Risk                       | Mitigation                                                        |
| -------------------------- | ----------------------------------------------------------------- |
| Recursive logic complexity | Keep pure helper functions (build_question_turn, etc.) with tests |
| Learning race conditions   | Use transactions and explicit locks when updating traits          |
| Cron permissions           | Configure pg_cron in schema and document schedule                 |
