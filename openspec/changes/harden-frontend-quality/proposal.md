# Change: Harden Frontend Quality

## Why

A comprehensive audit of the Vue 3 frontend revealed ~200 issues across type safety, memory management, error handling, accessibility, and i18n. While existing proposals address some type safety (`fix-type-safety-violations`) and component structure (`refactor-placeview-components`, `refactor-gameview-state-components`), critical gaps remain:

- **8 memory leaks** - Event listeners and timers not cleaned up on unmount
- **No global error handling** - Errors logged but users get no feedback
- **22+ accessibility violations** - Non-keyboard-accessible elements, missing ARIA labels
- **12+ i18n gaps** - Hardcoded strings, inconsistent pluralization
- **60+ functions missing return types** - Documentation and refactoring hazard
- **Store architecture issues** - Auth subscription leak, missing error states

This proposal creates a "11/10" frontend that Evan You would approve.

## Coordination with Other Changes

### Dependencies

- **harden-schema-security** - After schema moves to `api.*`, frontend Supabase calls need updating. This proposal includes those updates.
- **normalize-game-session-schema** - Eliminates JSONB columns that cause type issues. Some type fixes here depend on that change completing first.

### Complements (No Conflict)

- **fix-type-safety-violations** - Narrow scope (16 tasks). This proposal covers additional type issues not in that scope.
- **refactor-placeview-components** - Structural refactor. This proposal focuses on quality issues regardless of structure.
- **refactor-gameview-state-components** - Structural refactor. Same as above.

### Execution Order Recommendation

1. `harden-schema-security` (database layer)
2. `normalize-game-session-schema` (eliminates JSONB)
3. This proposal (`harden-frontend-quality`)
4. `fix-type-safety-violations` (remaining type issues)
5. Component refactors (structural cleanup)

## What Changes

### Stream 1: Foundation Types

Define proper TypeScript types that are currently missing or using `any`:

- **GeoJSON types** - `GeoJSONGeometry`, `GeoJSONPolygon`, `GeoJSONMultiPolygon` for map data
- **Nominatim types** - Properly type API responses (interface exists but not used everywhere)
- **Database view types** - Add `game_session_stats` view to generated types
- **JSON column types** - Type `place`, `candidates`, `question`, `guess` columns properly

### Stream 2: Memory Safety

Fix all lifecycle issues that cause memory leaks:

- **useMapCamera.ts** - Add `onUnmounted` for map event listeners
- **PlacesLayer.vue** - Clean up 6 map event listeners on unmount
- **GamePlaceSearch.vue** - Clear debounce timeout on unmount
- **useTheme.ts** - Add system theme change listener with cleanup
- **useCinematicIntro.ts** - Store and cancel requestAnimationFrame
- **GameView.vue** - Clear redirect timeout on unmount
- **useStatistics.ts** - Add mounted check for async operations
- **auth.ts** - Store and call unsubscribe from `onAuthStateChange`

### Stream 3: Error Infrastructure

Establish consistent error handling throughout the frontend:

- **Global error handler** - Add `app.config.errorHandler` in main.ts
- **API error transformation** - Transform all Supabase errors to `ApiError` in lib/api
- **User feedback** - Add toast notifications for errors in GameActive, HomeView, PlaceView, GameSubmission
- **Missing try/catch** - Add error handling to unprotected async operations

### Stream 4: Type Completeness

Beyond the narrow scope of `fix-type-safety-violations`:

- **60+ missing return types** - Add explicit return types to all exported functions
- **9 non-null assertions** - Replace `!` with proper guards or type narrowing
- **Composable return types** - Define interfaces for all composable returns

### Stream 5: Store Hardening

Fix store architecture issues:

- **Auth store** - Add error state ref, fix subscription cleanup
- **GameSearch store** - Add loading/error state refs
- **Cross-store dependencies** - Move store access from setup level to actions
- **Tech debt cleanup** - Remove "temporary" status helpers from gameSession

### Stream 6: Accessibility

Make the frontend WCAG 2.1 AA compliant:

- **Keyboard accessibility** - Make logo, map markers keyboard-navigable
- **ARIA labels** - Add labels to all interactive elements
- **Form labels** - Associate labels with form inputs
- **Focus management** - Move focus on game state transitions
- **Screen reader text** - Internationalize sr-only text

### Stream 7: i18n Completion

Complete internationalization coverage:

- **Hardcoded strings** - Move "GitHub", placeholders, "Close" to translation keys
- **Pluralization format** - Standardize on ICU MessageFormat (not legacy pipe syntax)
- **Language names** - Internationalize language display names

### Stream 8: API Schema Alignment

Coordinate with `harden-schema-security`:

- **Update Supabase client** - Configure to use `api` schema
- **Update RPC calls** - Ensure all calls work with new schema structure
- **Update type generation** - Regenerate types after schema change

## Impact

- **Affected specs**: `frontend` (major additions to multiple requirements)
- **Affected code**:
  - `src/composables/` - Memory cleanup, return types
  - `src/stores/` - Error states, subscription cleanup
  - `src/views/` - Error handling, accessibility
  - `src/components/` - ARIA labels, keyboard navigation
  - `src/lib/` - API error transformation, types
  - `src/i18n/` - New translation keys
  - `src/main.ts` - Global error handler
  - `src/types/` - New type definitions

## Success Criteria

After this change:

- `bun run type-check` passes with zero `any` in application code
- `bun run lint` passes with zero eslint-disable comments for type rules
- No memory leaks detected in Chrome DevTools Memory panel
- All interactive elements keyboard-accessible
- No hardcoded user-facing strings outside i18n
- All errors surface to users via toast notifications
