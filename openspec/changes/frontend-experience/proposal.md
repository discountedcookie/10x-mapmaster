# Change: Frontend Experience

## Why

The frontend must present the map-centric, conversational experience described in `spec/ui.md`. With backend contracts stabilizing, we can implement the layout, chat interface, map visualization, and navigation flows.

## Scope

- Persistent MapLibre globe with deck.gl overlays
- Floating panel layout + route transitions
- Chat interface (messages, candidate list, contextual inputs)
- Navigation (avatar menu, theme/language switch, stats routes)
- Accessibility and i18n baseline (Tolgee wiring)

## Impact

- Provides end-to-end playable UI for QA and demos
- Surfaces algorithm confidence visually
- Enables Playwright suite to run against real UI

## Success Criteria

- `bun run dev` shows working home → game → submit flows
- Vitest coverage for stores/composables
- Playwright scenarios pass with mocked embeddings
- Accessibility checks (ARIA labels, keyboard nav) satisfied
