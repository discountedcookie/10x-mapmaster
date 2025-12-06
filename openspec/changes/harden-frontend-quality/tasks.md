# Tasks: Harden Frontend Quality

## 1. Foundation Types

### 1.1 GeoJSON Types

- [ ] 1.1.1 Create `src/types/geojson.ts` with `GeoJSONPoint`, `GeoJSONPolygon`, `GeoJSONMultiPolygon`, `GeoJSONGeometry` union type
- [ ] 1.1.2 Export from `src/types/index.ts` (create if not exists)
- [ ] 1.1.3 Update `PlaceView.vue` to use `GeoJSONGeometry` instead of `any` (lines 124, 137, 198, 252, 278)
- [ ] 1.1.4 Update `PlacesLayer.vue` to use proper GeoJSON types (line 60)
- [ ] 1.1.5 Update `useGameMap.ts` to use `GeoJSONGeometry` for `geometry` field (line 32)
- [ ] 1.1.6 Update `gameSessionView.ts` to use `GeoJSONGeometry` (line 23)

### 1.2 Nominatim Types

- [ ] 1.2.1 Verify `NominatimPlace` interface exists in `src/lib/places/types.ts`
- [ ] 1.2.2 Update `gameSearch.ts` to use `NominatimPlace[]` instead of `any[]` (line 34)
- [ ] 1.2.3 Export `NominatimPlace` from `src/lib/places/index.ts`

### 1.3 Database View Types

- [ ] 1.3.1 Add `game_session_stats` view to database schema if not present
- [ ] 1.3.2 Run `supabase gen types typescript` to regenerate `src/types/database.ts`
- [ ] 1.3.3 Update `useStatistics.ts` to remove `(supabase as any)` cast (line 78)

### 1.4 JSON Column Types

- [ ] 1.4.1 Create types for `PlaceJson`, `CandidateJson`, `QuestionJson`, `GuessJson` if not present
- [ ] 1.4.2 Update `useGameMap.ts` to use proper JSON types instead of double-cast through `unknown` (lines 38-41)
- [ ] 1.4.3 Update `GameActive.vue` to use proper session type (lines 34-39)
- [ ] 1.4.4 Update `GameWon.vue` to use proper session type (lines 31-37)

## 2. Memory Safety

### 2.1 useMapCamera Cleanup

- [ ] 2.1.1 Read `src/composables/map/useMapCamera.ts` to understand current cleanup pattern
- [ ] 2.1.2 Add `onUnmounted(() => cleanupMapListeners())` if not already auto-invoked
- [ ] 2.1.3 Verify cleanup is called when component unmounts (add test or manual verification)

### 2.2 PlacesLayer Cleanup

- [ ] 2.2.1 Read `src/components/map/PlacesLayer.vue` `setupEventListeners()` (lines 125-161)
- [ ] 2.2.2 Store references to all event handlers
- [ ] 2.2.3 Add `onUnmounted` hook to remove: `zoom`, `click` (x2), `mouseenter`, `mouseleave` listeners
- [ ] 2.2.4 Test by mounting/unmounting component and checking listener count

### 2.3 GamePlaceSearch Cleanup

- [ ] 2.3.1 Read `src/components/game/GamePlaceSearch.vue` debounce logic (lines 24, 37-45)
- [ ] 2.3.2 Add `onUnmounted(() => { if (debounceTimeout.value) clearTimeout(debounceTimeout.value) })`
- [ ] 2.3.3 Verify timeout is cleared on unmount

### 2.4 useTheme System Preference Listener

- [ ] 2.4.1 Read `src/composables/useTheme.ts` current implementation
- [ ] 2.4.2 Add `matchMedia('(prefers-color-scheme: dark)').addEventListener('change', handler)`
- [ ] 2.4.3 Add `onUnmounted` or return cleanup function to remove listener
- [ ] 2.4.4 Test by changing system theme with `preference = 'auto'`

### 2.5 useCinematicIntro RAF Cancellation

- [ ] 2.5.1 Read `src/composables/map/useCinematicIntro.ts` animation logic
- [ ] 2.5.2 Store `requestAnimationFrame` return value in variable
- [ ] 2.5.3 Cancel RAF when abort signal fires or on cleanup
- [ ] 2.5.4 Test by aborting mid-animation

### 2.6 GameView Timeout Cleanup

- [ ] 2.6.1 Read `src/views/GameView.vue` redirect timeout (lines 87-89)
- [ ] 2.6.2 Store timeout ID in ref
- [ ] 2.6.3 Add `onUnmounted` to clear timeout if pending

### 2.7 useStatistics Mounted Check

- [ ] 2.7.1 Read `src/composables/useStatistics.ts` async operations
- [ ] 2.7.2 Add `isMounted` ref or use `onUnmounted` flag
- [ ] 2.7.3 Check `isMounted` before setting refs after await
- [ ] 2.7.4 Consider adding AbortController for fetch cancellation

### 2.8 Auth Store Subscription Cleanup

- [ ] 2.8.1 Read `src/stores/auth.ts` `onAuthStateChange` call (line 63)
- [ ] 2.8.2 Store unsubscribe function: `const { data: { subscription } } = supabase.auth.onAuthStateChange(...)`
- [ ] 2.8.3 Add `$dispose` handler or expose cleanup function
- [ ] 2.8.4 Document singleton lifecycle expectations

## 3. Error Infrastructure

### 3.1 Global Error Handler

- [ ] 3.1.1 Read `src/main.ts` current setup
- [ ] 3.1.2 Add `app.config.errorHandler = (error, instance, info) => { ... }`
- [ ] 3.1.3 Log error with context using logger
- [ ] 3.1.4 Show user-friendly toast notification
- [ ] 3.1.5 Test by throwing error in component

### 3.2 API Error Transformation

- [ ] 3.2.1 Read `src/lib/api/index.ts` error handling
- [ ] 3.2.2 Update all `if (error) throw error` to `if (error) throw transformError(error)`
- [ ] 3.2.3 Ensure `transformError` from `src/lib/errors.ts` is used consistently
- [ ] 3.2.4 Test API error surfaces as `ApiError` with proper code

### 3.3 User Feedback - GameActive

- [ ] 3.3.1 Read `src/components/game/states/GameActive.vue` error handling (lines 90-92)
- [ ] 3.3.2 Import toast notification composable/function
- [ ] 3.3.3 Show toast on answer failure: `toast.error(t('game.answer_failed'))`
- [ ] 3.3.4 Add translation key for error message

### 3.4 User Feedback - HomeView

- [ ] 3.4.1 Read `src/views/HomeView.vue` error handling (lines 120-121)
- [ ] 3.4.2 Show toast on game start failure
- [ ] 3.4.3 Add translation key for error message

### 3.5 User Feedback - PlaceView

- [ ] 3.5.1 Read `src/views/PlaceView.vue` error handling (lines 92-93)
- [ ] 3.5.2 Show toast on fetch failure
- [ ] 3.5.3 Consider showing error state in UI (not just logging)

### 3.6 User Feedback - GameSubmission

- [ ] 3.6.1 Read `src/components/game/states/GameSubmission.vue` error handling (lines 31-33)
- [ ] 3.6.2 Show toast on submit failure
- [ ] 3.6.3 Add translation key for error message

### 3.7 Missing Try/Catch - gameSession

- [ ] 3.7.1 Read `src/stores/gameSession.ts` `fetchGameState` (lines 16-19)
- [ ] 3.7.2 Wrap in try/catch or use `withLoadingState`
- [ ] 3.7.3 Set error state on failure

### 3.8 Missing Try/Catch - onMounted Calls

- [ ] 3.8.1 Read `src/views/HomeView.vue` onMounted (lines 56-58)
- [ ] 3.8.2 Add error handling for `placesStore.fetchAllPlaces()`
- [ ] 3.8.3 Read `src/views/StatisticsView.vue` onMounted (lines 12-14)
- [ ] 3.8.4 Add error handling for `fetchStatistics()`

### 3.9 Missing .catch - useAutoRotation

- [ ] 3.9.1 Read `src/composables/map/useAutoRotation.ts` promise chain (lines 137-142)
- [ ] 3.9.2 Add `.catch()` for cinematicIntro promise
- [ ] 3.9.3 Log error and gracefully degrade

## 4. Type Completeness

### 4.1 Composable Return Types

- [ ] 4.1.1 Define return interface for `useMapCamera` and add explicit return type
- [ ] 4.1.2 Define return interface for `useAutoRotation` and add explicit return type
- [ ] 4.1.3 Define return interface for `usePlacePresentation` and add explicit return type
- [ ] 4.1.4 Define return interface for `useMapCenterTracking` and add explicit return type
- [ ] 4.1.5 Define return interface for `useGameMap` and add explicit return type
- [ ] 4.1.6 Define return interface for `useStatistics` and add explicit return type
- [ ] 4.1.7 Define return interface for `useTheme` and add explicit return type

### 4.2 Store Function Return Types

- [ ] 4.2.1 Add return types to `auth.ts` functions: `initialize`, `signOut`
- [ ] 4.2.2 Add return types to `places.ts` functions: `fetchAllPlaces`, `reset`
- [ ] 4.2.3 Review and add return types to `gameSession.ts` functions
- [ ] 4.2.4 Review and add return types to `gameSearch.ts` functions

### 4.3 View Function Return Types

- [ ] 4.3.1 Add return types to `PlaceView.vue` functions (15+ functions)
- [ ] 4.3.2 Add return types to `HomeView.vue` functions
- [ ] 4.3.3 Add return types to `GameView.vue` functions
- [ ] 4.3.4 Add return types to `LoginView.vue` and `SignupView.vue` functions
- [ ] 4.3.5 Add return types to `StatisticsView.vue` functions

### 4.4 Component Function Return Types

- [ ] 4.4.1 Add return types to `PlacesLayer.vue` functions
- [ ] 4.4.2 Add return types to `BaseMap.vue` functions
- [ ] 4.4.3 Add return types to `FloatingNavbar.vue` functions
- [ ] 4.4.4 Add return types to `GamePlaceSearch.vue` functions
- [ ] 4.4.5 Add return types to `GameActive.vue` functions
- [ ] 4.4.6 Add return types to `GameSubmission.vue` functions

### 4.5 Non-Null Assertion Fixes

- [ ] 4.5.1 Fix `PlacesLayer.vue` template assertions (lines 189-198) - add proper null checks
- [ ] 4.5.2 Fix `useAutoRotation.ts` array assertions (lines 43, 44, 68, 121) - add bounds checks
- [ ] 4.5.3 Review remaining `!` assertions and add type guards where needed

## 5. Store Hardening

### 5.1 Auth Store Error State

- [ ] 5.1.1 Add `const error = ref<string | null>(null)` to auth store
- [ ] 5.1.2 Set error in catch blocks of `initialize`, auth operations
- [ ] 5.1.3 Clear error on successful operations
- [ ] 5.1.4 Export error ref

### 5.2 GameSearch Store State

- [ ] 5.2.1 Add `loading` ref to gameSearch store
- [ ] 5.2.2 Add `error` ref to gameSearch store
- [ ] 5.2.3 Update `setSearchResultPlaces` to manage loading state if async
- [ ] 5.2.4 Export loading and error refs

### 5.3 Cross-Store Dependencies

- [ ] 5.3.1 Read `src/stores/gameSearch.ts` setup-level store access (line 7)
- [ ] 5.3.2 Move `useGameSessionStore()` call inside the computed that uses it
- [ ] 5.3.3 Test that store initialization order is no longer fragile

### 5.4 Tech Debt Cleanup

- [ ] 5.4.1 Read `src/stores/gameSession.ts` temporary helpers (lines 117-125)
- [ ] 5.4.2 Search codebase for usage of `isGameActive`, `isGameWon`, etc.
- [ ] 5.4.3 Update call sites to use `session.status` directly
- [ ] 5.4.4 Remove temporary helpers
- [ ] 5.4.5 OR: Mark as permanent and remove "temporary" comment

## 6. Accessibility

### 6.1 Keyboard Navigation - FloatingNavbar

- [ ] 6.1.1 Read `src/components/FloatingNavbar.vue` logo click handler (line 80)
- [ ] 6.1.2 Change `<div @click>` to `<button>` or `<RouterLink>`
- [ ] 6.1.3 Add `tabindex="0"` if keeping div
- [ ] 6.1.4 Add `@keydown.enter` and `@keydown.space` handlers
- [ ] 6.1.5 Add `role="link"` and `aria-label`

### 6.2 Keyboard Navigation - Map Markers

- [ ] 6.2.1 Read `src/components/map/PlaceMarker.vue` click handling
- [ ] 6.2.2 Make marker focusable with `tabindex="0"`
- [ ] 6.2.3 Add keyboard event handlers for activation
- [ ] 6.2.4 Add `role="button"` and `aria-label`

### 6.3 ARIA Labels - Interactive Elements

- [ ] 6.3.1 Add `aria-label` to FloatingNavbar user dropdown trigger (line 150)
- [ ] 6.3.2 Add `aria-label` to PlaceView close buttons (lines 483, 530)
- [ ] 6.3.3 Add `aria-hidden="true"` to GitHub SVG icons in Login/Signup views
- [ ] 6.3.4 Add `aria-label` to search clear button in GamePlaceSearch

### 6.4 Form Labels

- [ ] 6.4.1 Add `<label>` for HomeView description input (line 143-147) or use `aria-label`
- [ ] 6.4.2 Add `<label>` for GamePlaceSearch input (line 99-114) or use `aria-label`

### 6.5 Screen Reader Text

- [ ] 6.5.1 Internationalize "Close" sr-only text in `DialogContent.vue` (line 43)
- [ ] 6.5.2 Internationalize "Close" sr-only text in `DialogScrollContent.vue` (line 55)
- [ ] 6.5.3 Add sr-only text to `SheetContent.vue` close button (line 46-50)
- [ ] 6.5.4 Add `aria-hidden="true"` to decorative icons in StatisticsView

### 6.6 Focus Management

- [ ] 6.6.1 When game state changes in GameView, move focus to new content
- [ ] 6.6.2 When search results appear in GamePlaceSearch, announce to screen readers
- [ ] 6.6.3 When dialog/sheet opens, focus first interactive element

## 7. i18n Completion

### 7.1 Hardcoded Strings - Auth

- [ ] 7.1.1 Add `auth.github_button` translation key for "GitHub" text
- [ ] 7.1.2 Add `auth.email_placeholder` for email placeholder
- [ ] 7.1.3 Add `auth.password_placeholder` for password placeholder
- [ ] 7.1.4 Update LoginView.vue to use translation keys
- [ ] 7.1.5 Update SignupView.vue to use translation keys

### 7.2 Hardcoded Strings - UI

- [ ] 7.2.1 Add `common.close` translation key
- [ ] 7.2.2 Update DialogContent.vue sr-only text
- [ ] 7.2.3 Update DialogScrollContent.vue sr-only text

### 7.3 Pluralization Format

- [ ] 7.3.1 Read `src/i18n/locales/en.ts` for pipe syntax usage
- [ ] 7.3.2 Convert `places_remaining` (line 70) from pipe to ICU format
- [ ] 7.3.3 Verify all pluralization uses ICU MessageFormat
- [ ] 7.3.4 Test pluralization with different counts

### 7.4 Language Names

- [ ] 7.4.1 Move language names from hardcoded array to translation files
- [ ] 7.4.2 Create `languages.english`, `languages.spanish`, `languages.polish` keys
- [ ] 7.4.3 Update FloatingNavbar to use translated names

## 8. API Schema Alignment

### 8.1 Supabase Client Configuration

- [ ] 8.1.1 Read `src/lib/supabase.ts` current configuration
- [ ] 8.1.2 After `harden-schema-security` completes, update client to use `api` schema
- [ ] 8.1.3 Test all RPC calls work with new schema

### 8.2 Type Regeneration

- [ ] 8.2.1 After schema changes, run `supabase gen types typescript`
- [ ] 8.2.2 Verify generated types include `api` schema objects
- [ ] 8.2.3 Update imports if type paths changed

## 9. Verification

### 9.1 Type Check

- [ ] 9.1.1 Run `bun run type-check` - must pass with zero errors
- [ ] 9.1.2 Grep for remaining `as any` - should be zero in app code
- [ ] 9.1.3 Grep for `eslint-disable.*any` - should be zero

### 9.2 Lint Check

- [ ] 9.2.1 Run `bun run lint` - must pass with zero errors
- [ ] 9.2.2 Review any warnings and address if reasonable

### 9.3 Memory Leak Check

- [ ] 9.3.1 Open app in Chrome, navigate to a game, then home, repeat 10x
- [ ] 9.3.2 Check DevTools Memory panel - heap should not grow unbounded
- [ ] 9.3.3 Check for detached DOM nodes

### 9.4 Accessibility Check

- [ ] 9.4.1 Tab through entire app - all interactive elements reachable
- [ ] 9.4.2 Run axe DevTools audit - no critical/serious issues
- [ ] 9.4.3 Test with VoiceOver (macOS) or NVDA (Windows)

### 9.5 i18n Check

- [ ] 9.5.1 Search templates for quoted strings that look like user-facing text
- [ ] 9.5.2 Switch to Spanish/Polish - verify no English text remains
- [ ] 9.5.3 Verify pluralization works (1 candidate vs 5 candidates)

### 9.6 Error Handling Check

- [ ] 9.6.1 Disconnect network, try to start game - user sees error toast
- [ ] 9.6.2 Break API endpoint temporarily - user sees error, not blank screen
- [ ] 9.6.3 Trigger error in component - global handler catches and shows toast
