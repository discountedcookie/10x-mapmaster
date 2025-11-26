# Tasks: Frontend Experience

## Phase 1 – Layout & Navigation

- [ ] 1.1 Implement persistent MapLayout with globe + floating panel (openspec/specs/frontend/spec.md#single-map-instance)
- [ ] 1.2 Implement avatar menu (theme, language, auth actions) (spec/frontend.md#navigation-elements)
- [ ] 1.3 Wire routes (/ , /game/:id, /login, /signup, /stats, /stats/global) (spec/frontend.md#route-structure)

## Phase 2 – Home & Auth

- [ ] 2.1 Build Home panel with description input + onboarding copy (spec/frontend.md#panel-behavior)
- [ ] 2.2 Build Login/Signup panels with Supabase auth wiring (spec/ui.md#panel-behavior)

## Phase 3 – Game UI

- [ ] 3.1 Build chat message list component (user/system styling) (spec/frontend.md#chat-interface)
- [ ] 3.2 Implement contextual input area (question, guess, give up states) (spec/frontend.md#contextual-input-area)
- [ ] 3.3 Implement candidate list with confidence bars + map panning (spec/frontend.md#candidate-list-display)
- [ ] 3.4 Implement turn indicator + status badges (spec/frontend.md#turn-indicator)

## Phase 4 – Map Visualization

- [ ] 4.1 Integrate deck.gl PolygonLayer for candidate markers (spec/frontend.md#3d-extruded-markers)
- [ ] 4.2 Implement geographic region feedback + auto-framing (spec/frontend.md#map-visualization)
- [ ] 4.3 Implement win/end animations + map camera behaviors (spec/frontend.md#win/end-state)

## Phase 5 – Supporting Views

- [ ] 5.1 Implement Stats views (user + global) consuming Supabase views (spec/frontend.md#panel-behavior)
- [ ] 5.2 Implement language switch via Tolgee + browser detection (spec/frontend.md#internationalization)
- [ ] 5.3 Implement accessibility checklist (keyboard nav, ARIA labels, reduced motion) (spec/frontend.md#accessibility)

## Phase 6 – Testing

- [x] 6.1 Fix TypeScript errors in frontend (src/composables/map/useMapMarkers.ts, src/i18n/index.ts, src/stores/game.ts)
- [ ] 6.2 Vitest coverage for composables/stores (spec/operations.md#testing-strategy)
- [ ] 6.3 Playwright scenarios (win, give up, login flow) using mocks (spec/operations.md#testing-strategy)
