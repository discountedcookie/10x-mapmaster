# Design: Frontend Experience

## Execution Plan

1. **Layout + navigation** – Map layout, floating panel, avatar menu.
2. **Game UI** – Chat interface, candidate list, contextual inputs.
3. **Map visualization** – deck.gl PolygonLayer markers, auto-framing, geographic feedback.
4. **Supporting flows** – Auth views, stats, language/theme toggle.
5. **Quality** – Accessibility, i18n, tests.

## Dependencies

- Supabase types generated from database schema.
- Game core RPCs available (can mock while wiring UI).

## Agents

- **Primary:** @frontend-expert
- **Support:** build agent for tooling/CI

## Risks & Mitigations

| Risk               | Mitigation                                |
| ------------------ | ----------------------------------------- |
| Map performance    | Use deck.gl layers with throttled updates |
| Async state drift  | Fetch latest session after every RPC call |
| Accessibility gaps | Run axe + keyboard audit per route        |
